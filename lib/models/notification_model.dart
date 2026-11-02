class NotificationModel {
  final String id;
  final String userId;
  final String targetRole; // 'client' or 'provider' or 'all'
  final String targetName; // name of client or provider
  final String title;
  final String body;
  final String type; // 'new_order', 'order_accepted', etc.
  final String? orderId;
  final DateTime createdAt;
  bool isRead;

  // Compatibility getters
  String get message => body;
  DateTime get timestamp => createdAt;

  NotificationModel({
    required this.id,
    this.userId = '',
    this.targetRole = 'all',
    this.targetName = '',
    required this.title,
    String? body,
    String? message,
    this.type = 'general',
    this.orderId,
    required this.createdAt,
    this.isRead = false,
  }) : body = body ?? message ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'targetRole': targetRole,
      'targetName': targetName,
      'title': title,
      'body': body,
      'message': body,
      'type': type,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      targetRole: map['targetRole']?.toString() ?? '',
      targetName: map['targetName']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'general',
      orderId: map['orderId']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true || map['isRead'] == 1,
    );
  }
}
