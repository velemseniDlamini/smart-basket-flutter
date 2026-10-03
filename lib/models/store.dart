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
