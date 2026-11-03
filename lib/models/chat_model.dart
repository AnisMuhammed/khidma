class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'client' or 'provider'
  final String receiverId;
  final String receiverName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String? orderId;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.receiverName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
    if (orderId != null && orderId!.isNotEmpty) {
      map['orderId'] = orderId;
    }
    return map;
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedTime = DateTime.now();
    final rawTs = map['timestamp'];
    if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs != null) {
      try {
        parsedTime = (rawTs as dynamic).toDate();
      } catch (_) {
        parsedTime = DateTime.now();
      }
    }

    return ChatMessage(
      id: id,
      chatId: map['chatId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderRole: map['senderRole']?.toString() ?? 'client',
      receiverId: map['receiverId']?.toString() ?? '',
      receiverName: map['receiverName']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: parsedTime,
      isRead: map['isRead'] == true,
      orderId: map['orderId']?.toString(),
    );
  }
}

class ChatConversation {
  final String id;
  final String? orderId;
  final String clientId;
  final String clientName;
  final String? clientImage;
  final String providerId;
  final String providerName;
  final String? providerImage;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final int unreadCountClient;
  final int unreadCountProvider;
  final List<String> participants;

  const ChatConversation({
    required this.id,
    this.orderId,
    required this.clientId,
    required this.clientName,
    this.clientImage,
    required this.providerId,
    required this.providerName,
    this.providerImage,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    this.unreadCountClient = 0,
    this.unreadCountProvider = 0,
    required this.participants,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientImage': clientImage,
      'providerId': providerId,
      'providerName': providerName,
      'providerImage': providerImage,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCountClient': unreadCountClient,
      'unreadCountProvider': unreadCountProvider,
      'participants': participants,
    };
    if (orderId != null && orderId!.isNotEmpty) {
      map['orderId'] = orderId;
    }
    return map;
  }

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedTime = DateTime.now();
    final rawTs = map['lastMessageTime'];
    if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs != null) {
      try {
        parsedTime = (rawTs as dynamic).toDate();
      } catch (_) {
        parsedTime = DateTime.now();
      }
    }

    final pList = (map['participants'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return ChatConversation(
      id: id,
      orderId: map['orderId']?.toString(),
      clientId: map['clientId']?.toString() ?? '',
      clientName: map['clientName']?.toString() ?? '',
      clientImage: map['clientImage']?.toString(),
      providerId: map['providerId']?.toString() ?? '',
      providerName: map['providerName']?.toString() ?? '',
      providerImage: map['providerImage']?.toString(),
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageSenderId: map['lastMessageSenderId']?.toString() ?? '',
      lastMessageTime: parsedTime,
      unreadCountClient: (map['unreadCountClient'] as num?)?.toInt() ?? 0,
      unreadCountProvider: (map['unreadCountProvider'] as num?)?.toInt() ?? 0,
      participants: pList,
    );
  }
}
