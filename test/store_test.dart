import 'package:flutter_test/flutter_test.dart';
import 'package:smart_basket_flutter/models/store.dart';

void main() {
  test('only Shoprite and SPAR are available during training', () {
    expect(
      Store.availableStores.map((store) => store.name).toList(),
      ['Shoprite', 'SPAR'],
    );
  });
}