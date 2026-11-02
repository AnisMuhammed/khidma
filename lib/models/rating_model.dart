class RatingModel {
  final String id;
  final String orderId;
  final String providerId;
  final String clientName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.orderId,
    required this.providerId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      clientName: json['clientName']?.toString() ?? '',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'providerId': providerId,
      'clientName': clientName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

