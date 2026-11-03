import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import 'notification_service.dart';

/// Chat Service
/// مسؤولة عن إدارة المحادثات الفورية والرسائل اللحظية عبر Cloud Firestore
/// وربط العميل ومزود الخدمة في غرف محادثة مخصصة.
class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _chatsRef => _firestore.collection('chats');

  /// توليد معرف ثابت للغرفة يضمن وصول الطرفين لنفس المحادثة
  static String buildChatId({
    String? orderId,
    required String clientId,
    required String providerId,
  }) {
    if (orderId != null && orderId.trim().isNotEmpty) {
      return 'order_${orderId.trim()}';
    }
    final sorted = [clientId.trim(), providerId.trim()]..sort();
    return 'chat_${sorted[0]}_${sorted[1]}';
  }

  /// الاستماع للرسائل اللحظية لمحادثة معينة مرتبة زمنياً
  static Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage.fromMap(doc.id, data);
      }).toList();
    });
  }

  /// الاستماع لقائمة محادثات المستخدم (صندوق الوارد)
  static Stream<List<ChatConversation>> getConversationsStream(String userId) {
    if (userId.trim().isEmpty) {
      return Stream.value([]);
    }

    return _chatsRef
        .where('participants', arrayContains: userId.trim())
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatConversation.fromMap(doc.id, data);
      }).toList();

      // ترتيب المحادثات من الأحدث للأقدم
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return list;
    });
  }

  /// إرسال رسالة جديدة وتحديث ملخص المحادثة
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderRole, // 'client' or 'provider'
    required String receiverId,
    required String receiverName,
    required String text,
    String? orderId,
    String? clientImage,
    String? providerImage,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final messageId = 'MSG-${DateTime.now().millisecondsSinceEpoch}';

    // 1. تحديد هويات العميل والمزود لبيانات المحادثة
    final isClient = senderRole == 'client';
    final clientId = isClient ? senderId : receiverId;
    final clientName = isClient ? senderName : receiverName;
    final providerId = isClient ? receiverId : senderId;
    final providerName = isClient ? receiverName : senderName;

    final chatDocRef = _chatsRef.doc(chatId);
    final messageDocRef = chatDocRef.collection('messages').doc(messageId);

    try {
      // 2. حفظ الرسالة في subcollection
      final Map<String, dynamic> messageData = {
        'id': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'text': cleanText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };
      if (orderId != null && orderId.isNotEmpty) {
        messageData['orderId'] = orderId;
      }
      await messageDocRef.set(messageData);

      // 3. تحديث ملخص المحادثة الرئيسي
      final Map<String, dynamic> conversationData = {
        'id': chatId,
        'clientId': clientId,
        'clientName': clientName,
        'providerId': providerId,
        'providerName': providerName,
        'lastMessage': cleanText,
        'lastMessageSenderId': senderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [clientId, providerId],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (orderId != null && orderId.isNotEmpty) {
        conversationData['orderId'] = orderId;
      }

      if (clientImage != null && clientImage.isNotEmpty) {
        conversationData['clientImage'] = clientImage;
      }
      if (providerImage != null && providerImage.isNotEmpty) {
        conversationData['providerImage'] = providerImage;
      }

      // زيادة عداد غير المقروء للطرف المستقبل
      if (isClient) {
        conversationData['unreadCountProvider'] = FieldValue.increment(1);
      } else {
        conversationData['unreadCountClient'] = FieldValue.increment(1);
      }

      await chatDocRef.set(conversationData, SetOptions(merge: true));

      // 4. إرسال إشعار تنبيه للمستقبل
      final targetRole = isClient ? 'provider' : 'client';
      NotificationService.sendNotification(
        targetRole: targetRole,
        targetName: receiverName,
        userId: receiverId,
        title: 'رسالة جديدة من $senderName 💬',
        body: cleanText,
        type: 'chat',
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('Error sending chat message: $e');
    }
  }

  /// تمييز الرسائل كمقروءة وتصفير العداد للمستخدم الحالي
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String currentUserId,
    required String currentUserRole,
  }) async {
    try {
      final chatDocRef = _chatsRef.doc(chatId);

      // تصفير عداد غير المقروء في ملخص المحادثة
      final isClient = currentUserRole == 'client';
      await chatDocRef.set({
        if (isClient) 'unreadCountClient': 0 else 'unreadCountProvider': 0,
      }, SetOptions(merge: true));

      // تحديث الرسائل غير المقروءة الواردة لهذا المستخدم
      final unreadSnap = await chatDocRef
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .limit(20)
          .get();

      if (unreadSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in unreadSnap.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
}
