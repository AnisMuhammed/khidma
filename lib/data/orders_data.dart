import '../models/order_model.dart';

/// طلبات العميل الحقيقية (تُجلب من Firestore و SQLite)
List<OrderModel> clientOrdersData = [];

List<OrderModel> get ordersData => clientOrdersData;

/// إضافة طلب جديد ومزامنته بين العميل ومزود الخدمة
void addNewOrder(OrderModel order) {
  clientOrdersData.removeWhere((o) => o.id == order.id);
  clientOrdersData.insert(0, order);
  providerOrdersData.removeWhere((o) => o.id == order.id);
  providerOrdersData.insert(0, order);
}

/// طلبات مزود الخدمة الحقيقية (تُجلب من Firestore و SQLite)
List<OrderModel> providerOrdersData = [];
