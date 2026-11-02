import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/user_session.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _keyNotifications = 'khidma_notifications_list';
  static final ValueNotifier<List<NotificationModel>> notificationsNotifier =
      ValueNotifier<List<NotificationModel>>([]);

  static CollectionReference get _notifsRef =>
      FirebaseFirestore.instance.collection('notifications');

  /// تهيئة واسترجاع الإشعارات المخزنة
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyNotifications);
      if (saved != null) {
        final List list = jsonDecode(saved);
        notificationsNotifier.value = list
            .map((m) => NotificationModel.fromMap(m))
            .toList();
      }
      // جلب من Firestore إذا توفر اتصال
      await fetchRemoteNotifications();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// إرسال إشعار جديد لمستخدم أو مزود
  static Future<void> sendNotification({
    required String targetRole, // 'client' or 'provider' or 'all'
    String targetName = '',
    String userId = '',
    required String title,
    required String body,
    String type = 'general',
    String? orderId,
  }) async {
    final notif = NotificationModel(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      targetRole: targetRole,
      targetName: targetName,
      title: title,
      body: body,
      type: type,
      orderId: orderId,
      createdAt: DateTime.now(),
    );

    final current = List<NotificationModel>.from(notificationsNotifier.value);
    current.insert(0, notif);
    notificationsNotifier.value = current;

    await _saveToLocal();

    // حفظ في Firestore
    try {
      await _notifsRef.doc(notif.id).set(notif.toMap());
    } catch (e) {
      debugPrint('Error saving remote notification: $e');
    }
  }

  /// جلب الإشعارات الخاصة بالمستخدم الحالي بالاعتماد على معرف المستخدم الفريد (UID)
  static List<NotificationModel> getForCurrentUser() {
    final role = UserSession.currentUserRole;
    final currentUserId = role == 'provider'
        ? UserSession.currentProvider.id
        : UserSession.currentUser.id;
    final currentName = role == 'provider'
        ? UserSession.currentProvider.name
        : UserSession.currentUser.name;

    return notificationsNotifier.value.where((n) {
      if (n.targetRole == 'all') return true;
      if (n.targetRole == role) {
        // المطابقة الأساسية عبر معرف المستخدم الفريد UID
        if (n.userId.isNotEmpty && currentUserId.isNotEmpty) {
          return n.userId == currentUserId;
        }
        // دعم تراجعي للمطابقة بالاسم فقط إذا كان كلاهما غير فارغ
        if (n.targetName.isNotEmpty && currentName.isNotEmpty) {
          return n.targetName.toLowerCase() == currentName.toLowerCase();
        }
        return false;
      }
      return false;
    }).toList();
  }

  /// جلب الإشعارات من Firestore
  static Future<void> fetchRemoteNotifications() async {
    try {
      final snapshot = await _notifsRef
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final remote = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NotificationModel.fromMap(data);
        }).toList();

        final Map<String, NotificationModel> map = {};
        for (final n in notificationsNotifier.value) {
          map[n.id] = n;
        }
        for (final n in remote) {
          map[n.id] = n;
        }
        notificationsNotifier.value = map.values.toList();
        await _saveToLocal();
      }
    } catch (e) {
      debugPrint('Error fetching remote notifications: $e');
    }
  }

  /// تحديد الإشعار كمقروء
  static Future<void> markAsRead(String notifId) async {
    final current = List<NotificationModel>.from(notificationsNotifier.value);
    final index = current.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      current[index].isRead = true;
      notificationsNotifier.value = current;
      await _saveToLocal();
    }
  }

  /// حذف إشعار محدد
  static Future<void> deleteNotification(String notifId) async {
    final current = List<NotificationModel>.from(notificationsNotifier.value);
    current.removeWhere((n) => n.id == notifId);
    notificationsNotifier.value = current;
    await _saveToLocal();
    try {
      await _notifsRef.doc(notifId).delete();
    } catch (_) {}
  }

  /// مسح جميع الإشعارات للمستخدم
  static Future<void> clearAll() async {
    notificationsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotifications);
  }

  static Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(
        notificationsNotifier.value.map((n) => n.toMap()).toList(),
      );
      await prefs.setString(_keyNotifications, jsonStr);
    } catch (_) {}
  }
}
