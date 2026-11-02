import '../models/order_model.dart';
import '../models/rating_model.dart';
import '../models/service_model.dart';
import '../data/services_data.dart';

/// Remote API Service (Stub Layer)
/// الطبقة الفعلية للبيانات هي Firestore.
/// هذه الخدمة تعمل كـ stub صامت حتى لا تكسر شيء.
class ApiService {
  /// جلب الخدمات — يعيد البيانات المحلية مباشرة
  static Future<List<ServiceModel>> fetchServices() async {
    return servicesData;
  }

  /// إنشاء طلب — يعيد true صامتاً (الحفظ الفعلي في Firestore)
  static Future<bool> createOrder(OrderModel order) async {
    return true;
  }

  /// تحديث حالة الطلب — يعيد true صامتاً (التحديث الفعلي في Firestore)
  static Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    return true;
  }

  /// رفع صورة — يعيد المسار المحلي (الرفع الفعلي يحتاج Firebase Storage)
  static Future<String> uploadWorkImage({
    required String localPath,
    required bool isBefore,
  }) async {
    return localPath;
  }

  /// إرسال تقييم — يعيد true صامتاً (الحفظ الفعلي في Firestore)
  static Future<bool> submitRating(RatingModel rating) async {
    return true;
  }
}
