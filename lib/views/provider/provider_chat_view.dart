import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/user_session.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';

class ProviderChatView extends StatelessWidget {
  const ProviderChatView({super.key});

  String _formatTime(DateTime dt) {
    final isAr = AppLanguageManager.isArabic;
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0 && dt.day == now.day) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period =
          isAr ? (dt.hour >= 12 ? 'م' : 'ص') : (dt.hour >= 12 ? 'PM' : 'AM');
      return '$hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && dt.day != now.day)) {
      return AppStrings.t('أمس', 'Yesterday');
    } else if (difference.inDays < 7) {
      final daysAr = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      final daysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return isAr ? daysAr[dt.weekday % 7] : daysEn[dt.weekday % 7];
    } else {
      return '${dt.year}/${dt.month}/${dt.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final providerId = UserSession.currentProvider.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('رسائل ومحادثات العملاء', 'Client Messages')),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: ChatService.getConversationsStream(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 70,
                      color: colors.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.t(
                        'لا توجد محادثات جارية حالياً',
                        'No ongoing conversations',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.t(
                        'ستظهر هنا الرسائل والمحادثات المباشرة مع العملاء فور بدئها.',
                        'Conversations and direct messages with clients will appear here as soon as they start.',
                      ),
                      style: TextStyle(color: colors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final hasUnread = chat.unreadCountProvider > 0;
              final imageProvider =
                  AppImageHelper.getImageProvider(chat.clientImage);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                elevation: hasUnread ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: hasUnread
                        ? colors.primary.withValues(alpha: 0.3)
                        : colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            colors.primary.withValues(alpha: 0.12),
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? Icon(
                                Icons.person_rounded,
                                color: colors.primary,
                                size: 28,
                              )
                            : null,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).cardColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.clientName.isNotEmpty
                              ? chat.clientName
                              : AppStrings.t('عميل خِدْمَة', 'Khidma Client'),
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.w900
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? colors.primary
                              : Colors.grey.shade500,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessageSenderId == providerId
                                ? '${AppStrings.t('أنت: ', 'You: ')}${chat.lastMessage}'
                                : chat.lastMessage,
                            style: TextStyle(
                              color: hasUnread
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${chat.unreadCountProvider}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: chat,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
