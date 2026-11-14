import 'package:flutter/material.dart';

class ProductCategory {
  final String name;
  final String emoji;
  final Color tint;

  const ProductCategory(this.name, this.emoji, this.tint);

  static const all = [
    ProductCategory('Dairy', '🥛', Color(0xFFE3F2FD)),
    ProductCategory('Bakery', '🍞', Color(0xFFFFF3E0)),
    ProductCategory('Fruit & Veg', '🥦', Color(0xFFE8F5E9)),
    ProductCategory('Meat', '🍗', Color(0xFFFFEBEE)),
    ProductCategory('Pantry', '🥫', Color(0xFFFFF8E1)),
    ProductCategory('Drinks', '🧃', Color(0xFFF3E5F5)),
    ProductCategory('Household', '🧽', Color(0xFFE0F7FA)),
    ProductCategory('Personal care', '🧴', Color(0xFFFCE4EC)),
  ];

  static ProductCategory named(String name) =>
      all.firstWhere((category) => category.name == name);
}

/// A common grocery item. Prices are not stored here: they come from the
/// store's official website, which this item links to.
class CatalogProduct {
  final String name;
  final String size;
  final String category;
  final String emoji;
  final bool popular;

  const CatalogProduct(
    this.name,
    this.size,
    this.category,
    this.emoji, {
    this.popular = false,
  });

  String get searchTerm => name;

  static const all = [
    CatalogProduct('Full cream milk', '2 L', 'Dairy', '🥛', popular: true),
    CatalogProduct('Large eggs', '18 pack', 'Dairy', '🥚', popular: true),
    CatalogProduct('Cheddar cheese', '900 g', 'Dairy', '🧀'),
    CatalogProduct('Plain yoghurt', '1 kg', 'Dairy', '🥣'),
    CatalogProduct('Butter', '500 g', 'Dairy', '🧈'),
    CatalogProduct('White bread', '700 g', 'Bakery', '🍞', popular: true),
    CatalogProduct('Brown bread', '700 g', 'Bakery', '🍞'),
    CatalogProduct('Bread rolls', '6 pack', 'Bakery', '🥯'),
    CatalogProduct('Bananas', 'per kg', 'Fruit & Veg', '🍌', popular: true),
    CatalogProduct('Apples', '1.5 kg', 'Fruit & Veg', '🍎'),
    CatalogProduct('Potatoes', '2 kg', 'Fruit & Veg', '🥔'),
    CatalogProduct('Tomatoes', '1 kg', 'Fruit & Veg', '🍅'),
    CatalogProduct('Onions', '2 kg', 'Fruit & Veg', '🧅'),
    CatalogProduct('Chicken portions', '2 kg', 'Meat', '🍗', popular: true),
    CatalogProduct('Beef mince', '500 g', 'Meat', '🥩'),
    CatalogProduct('Boerewors', '1 kg', 'Meat', '🌭'),
    CatalogProduct('Maize meal', '5 kg', 'Pantry', '🌽', popular: true),
    CatalogProduct('Rice', '2 kg', 'Pantry', '🍚'),
    CatalogProduct('White sugar', '2.5 kg', 'Pantry', '🍬'),
    CatalogProduct('Sunflower oil', '2 L', 'Pantry', '🫗'),
    CatalogProduct('Baked beans', '410 g', 'Pantry', '🥫'),
    CatalogProduct('Rooibos tea', '80 bags', 'Drinks', '🍵'),
    CatalogProduct('Instant coffee', '200 g', 'Drinks', '☕'),
    CatalogProduct('Orange juice', '2 L', 'Drinks', '🧃'),
    CatalogProduct('Washing powder', '2 kg', 'Household', '🧺'),
    CatalogProduct('Dishwashing liquid', '750 ml', 'Household', '🧽'),
    CatalogProduct('Toilet paper', '9 rolls', 'Household', '🧻'),
    CatalogProduct('Toothpaste', '100 ml', 'Personal care', '🪥'),
    CatalogProduct('Bath soap', '4 pack', 'Personal care', '🧼'),
    CatalogProduct('Body lotion', '400 ml', 'Personal care', '🧴'),
  ];
}
