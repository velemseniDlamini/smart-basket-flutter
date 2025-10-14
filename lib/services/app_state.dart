import 'package:flutter/foundation.dart';
import '../models/detected_product.dart';
import '../models/store.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  // User state
  User? _currentUser;
  bool _isAuthenticated = false;

  // Shopping state
  Store? _selectedStore;
  List<DetectedProduct> _shoppingBasket = [];
  bool _isScanning = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  Store? get selectedStore => _selectedStore;
  List<DetectedProduct> get shoppingBasket => List.unmodifiable(_shoppingBasket);
  bool get isScanning => _isScanning;
  
  double get basketTotal {
    return _shoppingBasket.fold(0.0, (sum, product) => sum + product.lineTotal);
  }

  int get basketItemCount => _shoppingBasket.length;

  // Authentication methods
  void login(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _selectedStore = null;
    _shoppingBasket.clear();
    notifyListeners();
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
      (item) => item.productName.toLowerCase() == product.productName.toLowerCase(),
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
        _shoppingBasket[index] = _shoppingBasket[index].copyWith(quantity: newQuantity);
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
  Map<String, dynamic> generateReceipt() {
    if (_selectedStore == null || _shoppingBasket.isEmpty) {
      throw Exception('Cannot generate receipt: no store selected or basket is empty');
    }

    return {
      'storeName': _selectedStore!.name,
      'items': _shoppingBasket.map((product) => {
        'name': product.productName,
        'quantity': product.quantity,
        'unitPrice': product.price,
        'lineTotal': product.lineTotal,
      }).toList(),
      'total': basketTotal,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': _currentUser?.id ?? 'anonymous',
    };
  }

  void completeCheckout() {
    // Generate receipt data
    final receipt = generateReceipt();
    
    // Clear basket after successful checkout
    _shoppingBasket.clear();
    
    // You could save the receipt to local storage here
    // await ReceiptStorage.saveReceipt(receipt);
    
    notifyListeners();
  }
}
