import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.notification_important_rounded;
      case 'order_accepted':
        return Icons.thumb_up_alt_rounded;
      case 'order_rejected':
        return Icons.cancel_rounded;
      case 'order_completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getNotificationColor(String type, ColorScheme colors) {
    switch (type) {
      case 'new_order':
        return colors.primary;
      case 'order_accepted':
        return Colors.green;
      case 'order_rejected':
        return Colors.red;
      case 'order_completed':
        return Colors.teal;
      default:
        return colors.primary;
    }
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) {
      return AppStrings.t('الآن', 'Now');
    } else if (diff.inMinutes < 60) {
      return AppStrings.t(
        'منذ ${diff.inMinutes} دقيقة',
        '${diff.inMinutes} minutes ago',
      );
    } else if (diff.inHours < 24) {
      return AppStrings.t(
        'منذ ${diff.inHours} ساعة',
        '${diff.inHours} hours ago',
      );
    } else {
      return '${time.year}/${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        final isAr = AppLanguageManager.isArabic;

        return Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'الإشعارات' : 'Notifications'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: isAr ? 'مسح الكل' : 'Clear all',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          isAr ? 'مسح الإشعارات' : 'Clear Notifications',
                        ),
                        content: Text(
                          isAr
                              ? 'هل تريد مسح جميع الإشعارات؟'
                              : 'Do you want to clear all notifications?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(isAr ? 'إلغاء' : 'Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              isAr ? 'مسح' : 'Clear',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await NotificationService.clearAll();
                    }
                  },
                ),
              ],
            ),
            body: ValueListenableBuilder<List<NotificationModel>>(
              valueListenable: NotificationService.notificationsNotifier,
              builder: (context, allNotifications, _) {
                final userNotifications =
                    NotificationService.getForCurrentUser();

                if (userNotifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 70,
                            color: colors.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.t(
                              'لا توجد إشعارات حالياً',
                              'No notifications yet',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t(
                              'ستظهر هنا إشعارات الطلبات وتحديثات المواعيد فور وصولها.',
                              'Order notifications and appointment updates will appear here as soon as they arrive.',
                            ),
                            style: TextStyle(color: colors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: userNotifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = userNotifications[index];
                    final color = _getNotificationColor(item.type, colors);
                    final icon = _getNotificationIcon(item.type);

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        NotificationService.deleteNotification(item.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? Colors.transparent
                              : colors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(icon, color: color),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!item.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTimestamp(item.timestamp),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            NotificationService.markAsRead(item.id);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
      },
    );
  }
}
