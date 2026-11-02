import '../data/user_session.dart';
import '../services/local_db_service.dart';
import '../services/sqlite_service.dart';

/// Cart Repository
/// مسؤولة عن إدارة سلة الخدمات (قائمة الخدمات المحفوظة لطلبها لاحقاً)
/// وتخزينها في قاعدة البيانات المحلية (Local Database: SQLite + SharedPreferences)
class CartRepository {
  List<Map<String, dynamic>> getCartItems() {
    return LocalDbService.getCartItems();
  }

  Future<void> addToCart(Map<String, dynamic> item) async {
    await LocalDbService.addToCart(item);
    try {
      await SqliteService.addReservation({
        'id':
            item['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'clientId': UserSession.currentUser.id,
        'providerId': item['providerId'] ?? '',
        'providerName': item['providerName'] ?? '',
        'serviceName': item['title'] ?? item['serviceName'] ?? '',
        'profession': item['category'] ?? item['profession'] ?? '',
        'price': item['price'] ?? 'حسب الاتفاق',
        'date': DateTime.now().toString().split(' ')[0],
        'time': 'متاح',
      });
    } catch (_) {}
  }

  Future<void> removeFromCart(String itemId) async {
    await LocalDbService.removeFromCart(itemId);
    try {
      await SqliteService.removeReservation(itemId);
    } catch (_) {}
  }

  Future<void> clearCart() async {
    await LocalDbService.clearCart();
    try {
      await SqliteService.clearReservations();
    } catch (_) {}
  }
}
