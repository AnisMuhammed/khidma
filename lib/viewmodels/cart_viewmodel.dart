import 'package:flutter/material.dart';
import '../repositories/cart_repository.dart';

/// Cart ViewModel (MVVM)
/// View -> CartViewModel -> CartRepository -> SQLite (reservations)
class CartViewModel extends ChangeNotifier {
  final CartRepository _repository = CartRepository();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get itemCount => _items.length;

  CartViewModel() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getCartItems();
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String id,
    required String title,
    required String category,
    required String providerName,
    String? providerId,
    String? price,
  }) async {
    await _repository.addToCart({
      'id': id,
      'title': title,
      'category': category,
      'providerName': providerName,
      'providerId': providerId ?? '',
      'price': price ?? 'حسب الاتفاق',
      'addedAt': DateTime.now().toIso8601String(),
    });
    await loadCart();
  }

  Future<void> removeItem(String id) async {
    await _repository.removeFromCart(id);
    await loadCart();
  }

  Future<void> clearAll() async {
    await _repository.clearCart();
    await loadCart();
  }
}
