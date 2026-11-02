import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class ProviderChatView extends StatelessWidget {
  const ProviderChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final List<Map<String, String>> chats = [];

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('المحادثات', 'Conversations')),
          centerTitle: true,
        ),
        body: chats.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 70,
                        color: colors.primary.withValues(alpha: 0.5),
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
                          'ستظهر هنا المحادثات والرسائل المباشرة مع العملاء فور بدئها.',
                          'Conversations and direct messages with clients will appear here as soon as they start.',
                        ),
                        style: TextStyle(color: colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        chat['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(chat['msg']!),
                      trailing: Text(
                        chat['time']!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.chat);
                      },
                    ),
                  );
                },
              ),
      );
  }
}
