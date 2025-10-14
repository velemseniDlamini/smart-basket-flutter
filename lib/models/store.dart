class Store {
  final String id;
  final String name;
  final String icon;
  final String? description;

  const Store({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
  });

  // Predefined South African stores
  static const List<Store> availableStores = [
    Store(
      id: 'checkers',
      name: 'Checkers',
      icon: '🛒',
      description: 'Better and Better',
    ),
    Store(
      id: 'picknpay',
      name: 'Pick n Pay',
      icon: '🛍️',
      description: 'Doing good is good business',
    ),
    Store(
      id: 'woolworths',
      name: 'Woolworths',
      icon: '🛒',
      description: 'Good business journey',
    ),
    Store(
      id: 'shoprite',
      name: 'Shoprite',
      icon: '🛒',
      description: 'Low prices you can trust',
    ),
    Store(
      id: 'spar',
      name: 'SPAR',
      icon: '🛍️',
      description: 'We live here too',
    ),
    Store(
      id: 'makro',
      name: 'Makro',
      icon: '🏪',
      description: 'More for less',
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
