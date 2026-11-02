import 'package:flutter/material.dart';
import '../repositories/cart_repository.dart';

/// Cart ViewModel (MVVM)
/// View -> CartViewModel -> CartRepository -> Local Database
class CartViewModel extends ChangeNotifier {
  final CartRepository _repository = CartRepository();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  int get itemCount => _items.length;

  CartViewModel() {
    loadCart();
  }

  void loadCart() {
    _items = _repository.getCartItems();
    notifyListeners();
  }

  Future<void> addItem({
    required String id,
    required String title,
    required String category,
    required String providerName,
  }) async {
    await _repository.addToCart({
      'id': id,
      'title': title,
      'category': category,
      'providerName': providerName,
      'addedAt': DateTime.now().toIso8601String(),
    });
    loadCart();
  }

  Future<void> removeItem(String id) async {
    await _repository.removeFromCart(id);
    loadCart();
  }

  Future<void> clearAll() async {
    await _repository.clearCart();
    loadCart();
  }
}

