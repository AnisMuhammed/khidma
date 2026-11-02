import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';

enum OrderStatus {
  pending,
  accepted,
  inProgress,
  completed,
  rejected,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return AppStrings.t('جديد', 'New');
      case OrderStatus.accepted:
        return AppStrings.t('مقبول', 'Accepted');
      case OrderStatus.inProgress:
        return AppStrings.t('قيد التنفيذ', 'In progress');
      case OrderStatus.completed:
        return AppStrings.t('مكتمل', 'Completed');
      case OrderStatus.rejected:
        return AppStrings.t('مرفوض', 'Rejected');
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.accepted:
        return Icons.thumb_up_alt_outlined;
      case OrderStatus.inProgress:
        return Icons.timelapse_rounded;
      case OrderStatus.completed:
        return Icons.check_circle_rounded;
      case OrderStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  Color getColor(ColorScheme colors) {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return colors.primary;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
    }
  }
}

class OrderModel {
  final String id;

  // IDs مهمة للربط بين العميل ومزود الخدمة
  final String clientId;
  final String providerId;

  final String clientName;
  final String providerName;
  final String serviceName;
  final String description;
  final String notes;
  final String location;
  final String date;
  final String time;

  OrderStatus status;
  bool isRated;

  String? beforeImagePath;
  String? afterImagePath;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.clientName,
    required this.providerName,
    required this.serviceName,
    required this.description,
    this.notes = '',
    required this.location,
    required this.date,
    required this.time,
    this.status = OrderStatus.pending,
    this.isRated = false,
    this.beforeImagePath,
    this.afterImagePath,
  });

  /// نص الحالة للعرض
  String get statusText => status.label;

  /// أيقونة الحالة
  IconData get statusIcon => status.icon;

  /// لون الحالة بحسب نظام ألوان التطبيق
  Color getStatusColor(ColorScheme colors) => status.getColor(colors);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',

      clientId: json['clientId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',

      clientName: json['clientName']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',

      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),

      isRated: json['isRated'] == true,

      beforeImagePath:
          json['beforeImagePath']?.toString(),

      afterImagePath:
          json['afterImagePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'clientId': clientId,
      'providerId': providerId,

      'clientName': clientName,
      'providerName': providerName,
      'serviceName': serviceName,
      'description': description,
      'notes': notes,
      'location': location,
      'date': date,
      'time': time,

      'status': status.name,
      'isRated': isRated,

      'beforeImagePath': beforeImagePath,
      'afterImagePath': afterImagePath,
    };
  }
}