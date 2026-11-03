import '../data/user_session.dart';
import '../services/sqlite_service.dart';

/// Cart Repository
/// مسؤولة عن إدارة سلة الخدمات والحجوزات المؤجلة
/// وتخزينها في قاعدة البيانات المحلية (SQLite: جدول reservations) كمصدر وحيد وأساسي
class CartRepository {
  /// جلب الحجوزات المحفوظة من SQLite
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final clientId = UserSession.currentUser.id;
    final reservations = await SqliteService.getReservations(clientId);
    return reservations.map((r) {
      return {
        'id': r['id']?.toString() ?? '',
        'clientId': r['clientId']?.toString() ?? '',
        'providerId': r['providerId']?.toString() ?? '',
        'providerName': r['providerName']?.toString() ?? '',
        'serviceName': r['serviceName']?.toString() ?? '',
        'title': r['serviceName']?.toString() ?? '',
        'category': r['profession']?.toString() ?? '',
        'profession': r['profession']?.toString() ?? '',
        'price': r['price']?.toString() ?? 'حسب الاتفاق',
        'date': r['date']?.toString() ?? '',
        'time': r['time']?.toString() ?? '',
        'createdAt': r['createdAt']?.toString() ?? '',
      };
    }).toList();
  }

  /// إضافة خدمة أو مزود إلى الحجوزات المحفوظة في SQLite
  Future<void> addToCart(Map<String, dynamic> item) async {
    final clientId = (item['clientId']?.toString().isNotEmpty == true)
        ? item['clientId'].toString()
        : UserSession.currentUser.id;

    await SqliteService.addReservation({
      'id': item['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'clientId': clientId,
      'providerId': item['providerId']?.toString() ?? '',
      'providerName': item['providerName']?.toString() ?? '',
      'serviceName':
          (item['title'] ?? item['serviceName'] ?? '').toString(),
      'profession':
          (item['category'] ?? item['profession'] ?? '').toString(),
      'price': item['price']?.toString() ?? 'حسب الاتفاق',
      'date': item['date']?.toString() ??
          DateTime.now().toString().split(' ')[0],
      'time': item['time']?.toString() ?? 'متاح',
    });
  }

  /// حذف حجز محفوظ من SQLite
  Future<void> removeFromCart(String itemId) async {
    await SqliteService.removeReservation(itemId);
  }

  /// مسح جميع الحجوزات المحفوظة من SQLite
  Future<void> clearCart() async {
    await SqliteService.clearReservations();
  }
}
