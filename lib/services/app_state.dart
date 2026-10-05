import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/detected_product.dart';
import '../models/store.dart';
import '../models/user.dart' as app_user;

class AppState extends ChangeNotifier {
  AppState() {
    _applyAuthUser(_supabase.auth.currentUser);
    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      _applyAuthUser(state.session?.user);
    });
  }

  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  late final StreamSubscription<supabase.AuthState> _authSubscription;

  // User state
  app_user.User? _currentUser;
  bool _isAuthenticated = false;

  // Shopping state
  Store? _selectedStore;
  final List<DetectedProduct> _shoppingBasket = [];
  bool _isScanning = false;

  // Getters
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
    if (!_isAuthenticated) {
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
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> unlockWithBiometrics() async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics;
    final isSupported = await auth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      return false;
    }

    return auth.authenticate(
      localizedReason: 'Unlock Smart Basket with Face ID or fingerprint',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }

  Future<supabase.AuthResponse> signIn(String phoneNumber, String password) {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    return _supabase.auth.signInWithPassword(
      phone: normalizedPhone,
      password: password,
    );
  }

  Future<supabase.AuthResponse> signUp({
    required String name,
    required String phoneNumber,
    required String password,
  }) {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    return _supabase.auth.signUp(
      phone: normalizedPhone,
      password: password,
      data: {'full_name': name.trim()},
    );
  }

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
