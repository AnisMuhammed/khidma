import '../core/localization/app_strings.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/sqlite_service.dart';
import '../data/orders_data.dart';

/// Order Repository
/// مسؤولة عن إدارة دورة حياة الطلبات بين العميل ومزود الخدمة
/// ومزامنة الطلبات بين SQLite و Firestore و API.
class OrderRepository {
  List<OrderModel> getOrders() {
    return ordersData;
  }

  /// جلب طلبات العميل من Firestore و SQLite باستخدام clientId (UID)
  Future<List<OrderModel>> fetchOrdersForClient(String clientId) async {
    List<OrderModel> list = [];
    try {
      list = await FirestoreService.getOrdersForClient(clientId);
    } catch (_) {}

    if (list.isEmpty) {
      list = await SqliteService.getOrdersForClient(clientId);
    }

    clientOrdersData.clear();
    clientOrdersData.addAll(list);

    return clientOrdersData;
  }

  /// جلب طلبات مزود الخدمة من Firestore و SQLite باستخدام providerId (UID)
  Future<List<OrderModel>> fetchOrdersForProvider(String providerId) async {
    List<OrderModel> list = [];
    try {
      list = await FirestoreService.getOrdersForProvider(providerId);
    } catch (_) {}

    if (list.isEmpty) {
      list = await SqliteService.getOrdersForProvider(providerId);
    }

    providerOrdersData.clear();
    providerOrdersData.addAll(list);

    return providerOrdersData;
  }

  /// إنشاء طلب جديد
  Future<OrderModel> createOrder({
    required String clientId,
    required String providerId,
    required String clientName,
    required String providerName,
    required String serviceName,
    required String description,
    required String location,
    required String date,
    required String time,
    String notes = 'السعر اتفاقي بين العميل ومزود الخدمة',
  }) async {
    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      providerId: providerId,
      clientName: clientName,
      providerName: providerName,
      serviceName: serviceName,
      description: description,
      location: location,
      date: date,
      time: time,
      notes: notes,
      status: OrderStatus.pending,
    );

    // إضافة محليًا إلى قائمة الطلبات
    addNewOrder(newOrder);

    // حفظ في SQLite
    await SqliteService.insertOrder(newOrder);

    // حفظ في Firestore
    await FirestoreService.createOrder(newOrder);

    // إرسال إلى API
    await ApiService.createOrder(newOrder);

    // إرسال إشعار لمزود الخدمة بوجود طلب جديد
    await NotificationService.sendNotification(
      targetRole: 'provider',
      targetName: providerName,
      userId: providerId,
      title: AppStrings.t('طلب خدمة جديد 🔔', 'New service request 🔔'),
      body: AppStrings.t(
        'قام العميل $clientName بطلب خدمة $serviceName لموعد $date ($time).',
        'Client $clientName requested $serviceName for $date ($time).',
      ),
      orderId: newOrder.id,
    );

    return newOrder;
  }

  /// قبول الطلب
  Future<void> acceptOrder(String orderId) async {
    await updateStatus(orderId, OrderStatus.accepted);
    try {
      final order = ordersData.firstWhere(
        (o) => o.id == orderId,
        orElse: () => providerOrdersData.firstWhere((o) => o.id == orderId),
      );
      await NotificationService.sendNotification(
        targetRole: 'client',
        targetName: order.clientName,
        userId: order.clientId,
        title: AppStrings.t('تم قبول طلبك بنجاح ✓', 'Your request was accepted ✓'),
        body: AppStrings.t(
          'تم قبول طلبك لخدمة ${order.serviceName} من قبل مزود الخدمة ${order.providerName}.',
          'Your request for ${order.serviceName} was accepted by ${order.providerName}.',
        ),
        orderId: orderId,
      );
    } catch (_) {}
  }

  /// رفض الطلب
  Future<void> rejectOrder(String orderId) async {
    await updateStatus(orderId, OrderStatus.rejected);
    try {
      final order = ordersData.firstWhere(
        (o) => o.id == orderId,
        orElse: () => providerOrdersData.firstWhere((o) => o.id == orderId),
      );
      await NotificationService.sendNotification(
        targetRole: 'client',
        targetName: order.clientName,
        userId: order.clientId,
        title: AppStrings.t('اعتذار عن تنفيذ الطلب ✕', 'Request declined ✕'),
        body: AppStrings.t(
          'يعتذر مزود الخدمة ${order.providerName} عن تنفيذ طلب خدمة ${order.serviceName}.',
          '${order.providerName} is unable to carry out your ${order.serviceName} request.',
        ),
        orderId: orderId,
      );
    } catch (_) {}
  }

  /// بدء تنفيذ الطلب
  Future<void> startOrderWork(String orderId) async {
    await updateStatus(orderId, OrderStatus.inProgress);
  }

  /// إرفاق صورة قبل أو بعد تنفيذ الخدمة
  Future<void> attachWorkImage({
    required String orderId,
    required String imagePath,
    required bool isBefore,
  }) async {
    final remoteUrl = await ApiService.uploadWorkImage(
      localPath: imagePath,
      isBefore: isBefore,
    );

    final index = ordersData.indexWhere((o) => o.id == orderId);

    if (index != -1) {
      if (isBefore) {
        ordersData[index].beforeImagePath = remoteUrl;
      } else {
        ordersData[index].afterImagePath = remoteUrl;
      }

      await FirestoreService.createOrder(ordersData[index]);
    }
  }

  /// إكمال الطلب
  Future<void> completeOrder(String orderId) async {
    await updateStatus(orderId, OrderStatus.completed);
    try {
      final order = ordersData.firstWhere(
        (o) => o.id == orderId,
        orElse: () => providerOrdersData.firstWhere((o) => o.id == orderId),
      );
      await NotificationService.sendNotification(
        targetRole: 'client',
        targetName: order.clientName,
        userId: order.clientId,
        title: AppStrings.t('اكتمل تنفيذ الخدمة 🎉', 'Service completed 🎉'),
        body: AppStrings.t(
          'أكمل مزود الخدمة ${order.providerName} تنفيذ خدمة ${order.serviceName} بنجاح. نرجو تقييم الخدمة.',
          '${order.providerName} successfully completed your ${order.serviceName} service. Please rate the service.',
        ),
        orderId: orderId,
      );
    } catch (_) {}
  }

  /// تحديث حالة الطلب
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    // تحديث القائمة الرئيسية
    final index = ordersData.indexWhere((o) => o.id == orderId);

    if (index != -1) {
      ordersData[index].status = status;
    }

    // تحديث قائمة طلبات المزود
    final providerIndex = providerOrdersData.indexWhere((o) => o.id == orderId);

    if (providerIndex != -1) {
      providerOrdersData[providerIndex].status = status;
    }

    // تحديث SQLite
    await SqliteService.updateOrderStatus(orderId, status);

    // تحديث Firestore
    await FirestoreService.updateOrderStatus(orderId, status);
    // تحديث API
    await ApiService.updateOrderStatus(orderId, status);
  }

  /// تسجيل أن العميل قيّم الطلب
  Future<void> markOrderAsRated(String orderId) async {
    final index = ordersData.indexWhere((o) => o.id == orderId);

    if (index != -1) {
      ordersData[index].isRated = true;

      await FirestoreService.createOrder(ordersData[index]);
    }
  }
}
