import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/detected_product.dart';
import '../models/savings_card.dart';
import '../models/store.dart';
import '../models/user.dart' as app_user;
import 'location_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _applyAuthUser(_supabase.auth.currentUser);
    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      _applyAuthUser(state.session?.user);
    });
    _loadLocationPreference();
  }

  static const _locationPromptKey = 'location_prompt_done';

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  late final StreamSubscription<supabase.AuthState> _authSubscription;

  // User state
  app_user.User? _currentUser;
  bool _isAuthenticated = false;

  // Shopping state
  Store? _selectedStore;
  final List<DetectedProduct> _shoppingBasket = [];
  bool _isScanning = false;

  // Location state
  bool? _locationPromptDone;
  LocationStatus _locationStatus = LocationStatus.unknown;
  String? _locationLabel;
  bool _isLocating = false;

  // Savings cards (stored on this device, per user)
  final List<SavingsCard> _savingsCards = [];

  // Navigation state
  int _tabIndex = 0;
  String? _productCategory;

  // Getters
  bool? get locationPromptDone => _locationPromptDone;
  LocationStatus get locationStatus => _locationStatus;
  String? get locationLabel => _locationLabel;
  bool get isLocating => _isLocating;
  int get tabIndex => _tabIndex;
  List<SavingsCard> get savingsCards => List.unmodifiable(_savingsCards);
  String? get productCategory => _productCategory;

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  Store? get selectedStore => _selectedStore;
  List<DetectedProduct> get shoppingBasket =>
      List.unmodifiable(_shoppingBasket);
  bool get isScanning => _isScanning;

  double get basketTotal {
    return _shoppingBasket.fold(0.0, (sum, product) => sum + product.lineTotal);
  }

  int get basketItemCount => _shoppingBasket.length;

  void _applyAuthUser(supabase.User? authUser) {
    _currentUser = authUser == null
        ? null
        : app_user.User(
            id: authUser.id,
            email: authUser.email ?? '',
            name: authUser.userMetadata?['full_name'] as String? ??
                authUser.email?.split('@').first ??
                'Shopper',
            createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
          );
    _isAuthenticated = authUser != null;
    _loadSavingsCards();
    if (!_isAuthenticated) {
      _tabIndex = 0;
      _selectedStore = null;
      _shoppingBasket.clear();
    }
    notifyListeners();
  }

  static String normalizePhoneNumber(String phoneNumber) {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('+')) {
      return '+$digits';
    }
    return digits;
  }

  Future<bool> isBiometricsSupported() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        return false;
      }

      return await auth.authenticate(
        localizedReason: 'Unlock Smart Basket with Face ID or fingerprint',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<supabase.AuthResponse> signIn(String email, String password) async {
    final trimmedEmail = email.trim();

    return _supabase.auth.signInWithPassword(
      email: trimmedEmail,
      password: password,
    );
  }

  Future<supabase.AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    return _supabase.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: {'full_name': name.trim()},
    );
  }

  Future<void> _loadLocationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _locationPromptDone = prefs.getBool(_locationPromptKey) ?? false;
    } catch (_) {
      _locationPromptDone = false;
    }
    notifyListeners();
    if (_locationPromptDone!) {
      _applyLocation(await LocationService.currentIfGranted());
    }
  }

  void _applyLocation(LocationResult result) {
    _locationStatus = result.status;
    _locationLabel = result.label;
    notifyListeners();
  }

  /// Asks for location permission and finishes the location prompt.
  Future<LocationStatus> requestLocation() async {
    _isLocating = true;
    notifyListeners();
    final result = await LocationService.request();
    _isLocating = false;
    _applyLocation(result);
    await _finishLocationPrompt();
    return result.status;
  }

  Future<void> skipLocationPrompt() => _finishLocationPrompt();

  Future<void> _finishLocationPrompt() async {
    _locationPromptDone = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPromptKey, true);
    } catch (_) {}
  }

  String? get _savingsCardsKey =>
      _currentUser == null ? null : 'savings_cards_${_currentUser!.id}';

  Future<void> _loadSavingsCards() async {
    final key = _savingsCardsKey;
    _savingsCards.clear();
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(key);
      if (stored != null && key == _savingsCardsKey) {
        _savingsCards
          ..clear()
          ..addAll((jsonDecode(stored) as List)
              .map((json) => SavingsCard.fromJson(json as Map<String, dynamic>)));
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveSavingsCards() async {
    final key = _savingsCardsKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode(_savingsCards.map((card) => card.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> addSavingsCard({
    required SavingsProgram program,
    required String number,
    String? nickname,
  }) async {
    _savingsCards.add(SavingsCard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      program: program,
      number: number,
      nickname: nickname?.trim(),
    ));
    notifyListeners();
    await _saveSavingsCards();
  }

  Future<void> removeSavingsCard(String id) async {
    _savingsCards.removeWhere((card) => card.id == id);
    notifyListeners();
    await _saveSavingsCards();
  }

  // Navigation
  void setTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  void showProducts({String? category}) {
    _productCategory = category;
    _tabIndex = 1;
    notifyListeners();
  }

  void setProductCategory(String? category) {
    _productCategory = category;
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) =>
      _supabase.auth.resetPasswordForEmail(email.trim());

  Future<void> logout() => _supabase.auth.signOut();

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  // Store selection
  void selectStore(Store store) {
    _selectedStore = store;
    notifyListeners();
  }

  void clearStoreSelection() {
    _selectedStore = null;
    _shoppingBasket.clear();
    notifyListeners();
  }

  // Shopping basket management
  void addProductToBasket(DetectedProduct product) {
    // Check if product already exists
    final existingIndex = _shoppingBasket.indexWhere(
      (item) =>
          item.productName.toLowerCase() == product.productName.toLowerCase(),
    );

    if (existingIndex != -1) {
      // Update quantity of existing product
      _shoppingBasket[existingIndex] = _shoppingBasket[existingIndex].copyWith(
        quantity: _shoppingBasket[existingIndex].quantity + 1,
      );
    } else {
      // Add new product
      _shoppingBasket.add(product);
    }

    notifyListeners();
  }

  void removeProductFromBasket(int index) {
    if (index >= 0 && index < _shoppingBasket.length) {
      _shoppingBasket.removeAt(index);
      notifyListeners();
    }
  }

  void updateProductQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _shoppingBasket.length) {
      if (newQuantity <= 0) {
        removeProductFromBasket(index);
      } else {
        _shoppingBasket[index] =
            _shoppingBasket[index].copyWith(quantity: newQuantity);
        notifyListeners();
      }
    }
  }

  void clearBasket() {
    _shoppingBasket.clear();
    notifyListeners();
  }

  // Scanning state
  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // Checkout
  Future<Map<String, dynamic>> completeCheckout() async {
    if (_selectedStore == null || _shoppingBasket.isEmpty) {
      throw Exception(
          'Cannot generate receipt: no store selected or basket is empty');
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before generating a receipt.');
    }

    final receiptData = {
      'user_id': user.id,
      'store_name': _selectedStore!.name,
      'items': _shoppingBasket
          .map((product) => {
                'name': product.productName,
                'quantity': product.quantity,
                'unit_price': product.price,
                'line_total': product.lineTotal,
              })
          .toList(),
      'total': basketTotal,
    };

    final savedReceipt = await _supabase
        .from('shopping_receipts')
        .insert(receiptData)
        .select('id, created_at')
        .single();

    _shoppingBasket.clear();
    notifyListeners();
    return {...receiptData, ...savedReceipt};
  }
}
