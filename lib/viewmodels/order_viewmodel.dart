import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/user_session.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

/// Order ViewModel (MVVM)
/// View -> OrderViewModel -> OrderRepository
/// -> SQLite / Firestore / API
class OrderViewModel extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();

  bool isLoading = false;
  String? errorMessage;

  List<OrderModel> get orders => _repository.getOrders();

  List<OrderModel> get pendingOrders {
    return orders.where((o) => o.status == OrderStatus.pending).toList();
  }

  List<OrderModel> get inProgressOrders {
    return orders
        .where(
          (o) =>
              o.status == OrderStatus.inProgress ||
              o.status == OrderStatus.accepted,
        )
        .toList();
  }

  List<OrderModel> get completedOrders {
    return orders.where((o) => o.status == OrderStatus.completed).toList();
  }

  /// تحميل طلبات العميل أو المزود
  Future<void> loadOrders({String? clientId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final role = UserSession.currentUserRole;
      // استخدام UID الحقيقي من Firebase Auth
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final uid = (clientId != null && clientId.isNotEmpty)
          ? clientId
          : firebaseUid;

      if (uid.isEmpty) {
        // لم يسجل الدخول بعد
        isLoading = false;
        notifyListeners();
        return;
      }

      if (role == 'provider') {
        await _repository.fetchOrdersForProvider(uid);
      } else {
        await _repository.fetchOrdersForClient(uid);
      }
    } catch (e) {
      errorMessage = 'تعذر تحميل الطلبات';
      debugPrint('Load Orders Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// إنشاء طلب جديد بحالة "جديد"
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
  }) async {
    final order = await _repository.createOrder(
      clientId: clientId,
      providerId: providerId,
      clientName: clientName,
      providerName: providerName,
      serviceName: serviceName,
      description: description,
      location: location,
      date: date,
      time: time,
    );

    notifyListeners();

    return order;
  }

  /// قبول الطلب من المزود
  Future<void> acceptOrder(String orderId) async {
    await _repository.acceptOrder(orderId);
    notifyListeners();
  }

  /// رفض الطلب من المزود
  Future<void> rejectOrder(String orderId) async {
    await _repository.rejectOrder(orderId);
    notifyListeners();
  }

  /// بدء تنفيذ العمل
  Future<void> startWork(String orderId) async {
    await _repository.startOrderWork(orderId);
    notifyListeners();
  }

  /// إرفاق صورة قبل أو بعد العمل
  Future<void> attachWorkImage({
    required String orderId,
    required String imagePath,
    required bool isBefore,
  }) async {
    await _repository.attachWorkImage(
      orderId: orderId,
      imagePath: imagePath,
      isBefore: isBefore,
    );

    notifyListeners();
  }

  /// إنهاء واكتمال الطلب
  Future<void> completeOrder(String orderId) async {
    await _repository.completeOrder(orderId);
    notifyListeners();
  }

  /// تحديث حالة الطلب
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _repository.updateStatus(orderId, status);

    notifyListeners();
  }
}
