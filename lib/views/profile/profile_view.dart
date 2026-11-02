import 'package:flutter/material.dart';

import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/user_session.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        final isAr = AppLanguageManager.isArabic;

        return Scaffold(
            appBar: AppBar(
              title: Text(AppStrings.tr('profile')),
              centerTitle: true,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 10),

                // Profile Header
                ValueListenableBuilder<UserModel>(
                  valueListenable: UserSession.clientNotifier,
                  builder: (context, user, _) {
                    final imageProvider = AppImageHelper.getImageProvider(
                      user.profileImagePath,
                    );

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(Icons.person_rounded, size: 42)
                                  : null,
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    user.email.isNotEmpty
                                        ? user.email
                                        : user.phone,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.editProfile,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Text(
                  AppStrings.tr('profile'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  title: isAr ? 'الإشعارات' : 'Notifications',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
                ),

                const SizedBox(height: 15),

                Text(
                  isAr ? 'التطبيق' : 'App',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                _ProfileTile(
                  icon: Icons.settings_outlined,
                  title: AppStrings.tr('settings'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),

                const SizedBox(height: 20),

                // Logout Button
                FilledButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(AppStrings.tr('logout')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRtl = AppLanguageManager.currentDirection == TextDirection.rtl;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(title),
        trailing: Icon(
          isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        ),
        onTap: onTap,
      ),
    );
  }
}
