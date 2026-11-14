class Store {
  final String id;
  final String name;
  final String icon;
  final String? description;
  final String websiteUrl;
  final String websiteLabel;

  /// Official site search URL; `{q}` is replaced by the search term. Null when
  /// the store has no searchable online catalogue.
  final String? searchUrlTemplate;

  /// Official specials / leaflets page.
  final String specialsUrl;

  const Store({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
    required this.websiteUrl,
    required this.websiteLabel,
    this.searchUrlTemplate,
    required this.specialsUrl,
  });

  bool get hasOnlineCatalogue => searchUrlTemplate != null;

  /// Where to look up [query] on the store's official website.
  Uri productUrl(String query) {
    final template = searchUrlTemplate;
    if (template == null) return Uri.parse(specialsUrl);
    return Uri.parse(
      template.replaceFirst('{q}', Uri.encodeQueryComponent(query.trim())),
    );
  }

  // Predefined South African stores
  static const List<Store> availableStores = [
    Store(
      id: 'shoprite',
      name: 'Shoprite',
      icon: '🛒',
      description: 'Low prices you can trust',
      websiteUrl: 'https://www.shoprite.co.za',
      websiteLabel: 'shoprite.co.za',
      searchUrlTemplate: 'https://www.shoprite.co.za/search?Search={q}',
      specialsUrl: 'https://www.shoprite.co.za/specials',
    ),
    Store(
      id: 'spar',
      name: 'SPAR',
      icon: '🛍️',
      description: 'We live here too',
      websiteUrl: 'https://www.spar.co.za',
      websiteLabel: 'spar.co.za',
      specialsUrl: 'https://www.spar.co.za/region-and-national-specials',
    ),
  ];

  @override
  String toString() => 'Store(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
