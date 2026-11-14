import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/store.dart';

/// A product as listed on the store's official website.
class LiveProduct {
  final String name;
  final String price;
  final String? wasPrice;
  final String? imageUrl;
  final String? size;

  /// Text shown before the price, such as "Buy Any 2 for".
  final String? priceLabel;

  /// Promotion badge, such as "Save R 11.00".
  final String? badge;

  const LiveProduct({
    required this.name,
    required this.price,
    this.wasPrice,
    this.imageUrl,
    this.size,
    this.priceLabel,
    this.badge,
  });

  factory LiveProduct.fromJson(Map<String, dynamic> json) => LiveProduct(
        name: json['name'] as String,
        price: json['price'] as String,
        wasPrice: _nonEmpty(json['wasPrice']),
        imageUrl: _nonEmpty(json['imageUrl']),
        size: _nonEmpty(json['size']),
        priceLabel: _nonEmpty(json['priceLabel']),
        badge: _nonEmpty(json['badge']),
      );

  static String? _nonEmpty(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'wasPrice': wasPrice,
        'imageUrl': imageUrl,
        'size': size,
        'priceLabel': priceLabel,
        'badge': badge,
      };
}

/// Reads product photos and prices from the stores' official websites by
/// loading their pages in an invisible in-app browser, the same pages a
/// shopper would see. Pages are loaded one at a time and results are cached on
/// the device for a few hours.
///
/// * Shoprite: the top search result for each catalogue item.
/// * SPAR: spar.co.za has no product search, so this reads SPAR's current
///   national specials and matches catalogue items against them.
class LiveCatalogService extends ChangeNotifier {
  LiveCatalogService._();
  static final instance = LiveCatalogService._();

  static const _cacheKey = 'live_catalog_cache_v2';
  static const _cacheLifetime = Duration(hours: 6);
  static const _pageTimeout = Duration(seconds: 20);
  static const _sparSpecialsKey = 'spar:__specials__';
  static const _sparSpecialsUrl = 'https://www.spar.co.za/national-specials';

  /// Extracts the first product tile on a Shoprite search results page.
  static const _shopriteScript = '''
(() => {
  const tile = document.querySelector('[class*="product-card_container"]');
  if (!tile) return '';
  const text = (selector) => {
    const el = tile.querySelector(selector);
    return el ? el.textContent.replace(/\\s+/g, '').trim() : null;
  };
  const img = tile.querySelector('img');
  const name = tile.querySelector('[class*="product-card_product-name"]');
  return JSON.stringify({
    name: name ? name.textContent.trim() : (img ? img.alt.trim() : ''),
    price: text('[class*="product-card_product-price"]'),
    wasPrice: text('[class*="product-card_discounted-price"]'),
    imageUrl: img ? (img.currentSrc || img.src) : null,
  });
})()
''';

  /// Extracts every special on SPAR's national specials page.
  static const _sparScript = '''
(() => {
  const cards = [...document.querySelectorAll('a[class*="_card_"]')]
    .filter((card) => card.querySelector('[class*="_priceSection_"]'));
  if (!cards.length) return '';
  const text = (card, selector) => {
    const el = card.querySelector(selector);
    return el ? el.textContent.replace(/\\s+/g, ' ').trim() : null;
  };
  return JSON.stringify(cards.map((card) => {
    const img = card.querySelector('figure img') || card.querySelector('img');
    return {
      name: text(card, '[class*="_title_"]') || (img ? img.alt.trim() : ''),
      size: text(card, '[class*="_bodyCopy_"]:not([class*="Wrapper"]):not([class*="Row"])'),
      priceLabel: text(card, '[class*="_priceLabel_"]'),
      price: text(card, '[class*="_price_"]:not([class*="Label"]):not([class*="Section"])'),
      badge: text(card, '[class*="_label_"]'),
      imageUrl: img ? (img.currentSrc || img.src) : null,
    };
  }));
})()
''';

  final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  final Map<String, LiveProduct> _products = {};
  final Map<String, DateTime> _fetchedAt = {};
  List<LiveProduct>? _sparSpecials;
  final Set<String> _failed = {};
  final Queue<String> _queue = Queue();
  bool _busy = false;
  bool _cacheLoaded = false;

  static bool supports(Store store) =>
      store.id == 'shoprite' || store.id == 'spar';

  /// SPAR's current national specials, once loaded.
  List<LiveProduct>? get sparSpecials => _sparSpecials;

  bool get sparSpecialsLoading =>
      _sparSpecials == null &&
      !_failed.contains(_sparSpecialsKey) &&
      _queue.contains(_sparSpecialsKey);

  LiveProduct? productFor(Store store, String term) {
    if (store.id == 'spar') return _matchSparSpecial(term);
    return _products[_key(store, term)];
  }

  bool isLoading(Store store, String term) {
    if (store.id == 'spar') return sparSpecialsLoading;
    final key = _key(store, term);
    return !_products.containsKey(key) &&
        !_failed.contains(key) &&
        _queue.contains(key);
  }

  /// Queues a lookup for [term] at [store] unless a fresh result is cached.
  Future<void> request(Store store, String term) async {
    await _enqueue(
      store.id == 'spar' ? _sparSpecialsKey : _key(store, term),
    );
  }

  Future<void> requestSparSpecials() => _enqueue(_sparSpecialsKey);

  static String _key(Store store, String term) =>
      '${store.id}:${term.trim().toLowerCase()}';

  Future<void> _enqueue(String key) async {
    await _loadCache();
    final fetched = _fetchedAt[key];
    final fresh = fetched != null &&
        DateTime.now().difference(fetched) < _cacheLifetime;
    if (fresh || _failed.contains(key) || _queue.contains(key)) return;
    // The specials list feeds many cards, so fetch it first.
    if (key == _sparSpecialsKey) {
      _queue.addFirst(key);
    } else {
      _queue.add(key);
    }
    notifyListeners();
    _pump();
  }

  Future<void> _pump() async {
    if (_busy) return;
    _busy = true;
    while (_queue.isNotEmpty) {
      final key = _queue.first;
      final succeeded = key == _sparSpecialsKey
          ? await _fetchSparSpecials()
          : await _fetchShoprite(key);
      _queue.removeFirst();
      if (succeeded) {
        _fetchedAt[key] = DateTime.now();
        _failed.remove(key);
        unawaited(_saveCache());
      } else {
        _failed.add(key);
      }
      notifyListeners();
    }
    _busy = false;
    notifyListeners();
  }

  Future<bool> _fetchShoprite(String key) async {
    final term = key.substring(key.indexOf(':') + 1);
    final store = Store.availableStores.firstWhere((s) => s.id == 'shoprite');
    final result = await _loadAndExtract(store.productUrl(term), _shopriteScript);
    if (result is! Map<String, dynamic>) return false;
    final product = _toProduct(result);
    if (product == null) return false;
    _products[key] = product;
    return true;
  }

  Future<bool> _fetchSparSpecials() async {
    final result =
        await _loadAndExtract(Uri.parse(_sparSpecialsUrl), _sparScript);
    if (result is! List) return false;
    final specials = result
        .whereType<Map<String, dynamic>>()
        .map(_toProduct)
        .whereType<LiveProduct>()
        .toList();
    if (specials.isEmpty) return false;
    _sparSpecials = specials;
    return true;
  }

  /// Loads [url] and polls [script] until it returns data, because both sites
  /// render their products a few seconds after the page loads.
  Future<Object?> _loadAndExtract(Uri url, String script) async {
    try {
      await controller.loadRequest(url);
      final deadline = DateTime.now().add(_pageTimeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 1));
        final decoded =
            _decode(await controller.runJavaScriptReturningResult(script));
        if (decoded != null) return decoded;
      }
    } catch (error) {
      debugPrint('Live catalogue lookup failed for $url: $error');
    }
    return null;
  }

  static Object? _decode(Object? result) {
    Object? value = result;
    // Depending on the platform the result may be double-encoded JSON.
    for (var i = 0; i < 2 && value is String; i++) {
      if (value.isEmpty) return null;
      try {
        value = jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    return value is String ? null : value;
  }

  static LiveProduct? _toProduct(Map<String, dynamic> json) {
    final name = json['name'];
    final price = json['price'];
    if (name is! String || name.isEmpty || price is! String || price.isEmpty) {
      return null;
    }
    return LiveProduct.fromJson(json);
  }

  /// Finds the SPAR special whose name contains every word of [term].
  LiveProduct? _matchSparSpecial(String term) {
    final specials = _sparSpecials;
    if (specials == null) return null;
    final words = _words(term);
    if (words.isEmpty) return null;
    for (final special in specials) {
      final nameWords = _words(special.name);
      if (words.every(nameWords.contains)) return special;
    }
    return null;
  }

  static Set<String> _words(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((word) => word.length >= 3)
      .map((word) => word.endsWith('s') ? word.substring(0, word.length - 1) : word)
      .toSet();

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_cacheKey);
      if (stored == null) return;
      final cache = jsonDecode(stored) as Map<String, dynamic>;
      final products = cache['products'] as Map<String, dynamic>? ?? {};
      for (final entry in products.entries) {
        final data = entry.value as Map<String, dynamic>;
        _products[entry.key] =
            LiveProduct.fromJson(data['product'] as Map<String, dynamic>);
        _fetchedAt[entry.key] = DateTime.parse(data['fetchedAt'] as String);
      }
      final spar = cache['sparSpecials'] as Map<String, dynamic>?;
      if (spar != null) {
        _sparSpecials = (spar['items'] as List)
            .map((json) => LiveProduct.fromJson(json as Map<String, dynamic>))
            .toList();
        _fetchedAt[_sparSpecialsKey] =
            DateTime.parse(spar['fetchedAt'] as String);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'products': {
            for (final key in _products.keys)
              key: {
                'product': _products[key]!.toJson(),
                'fetchedAt': _fetchedAt[key]!.toIso8601String(),
              },
          },
          if (_sparSpecials != null)
            'sparSpecials': {
              'items': _sparSpecials!.map((p) => p.toJson()).toList(),
              'fetchedAt': _fetchedAt[_sparSpecialsKey]!.toIso8601String(),
            },
        }),
      );
    } catch (_) {}
  }
}
