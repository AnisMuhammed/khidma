import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme_manager.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        final isAr = AppLanguageManager.isArabic;
        final isRtl = isAr;

        return Scaffold(
            appBar: AppBar(
              title: Text(isAr ? 'الإعدادات' : 'Settings'),
              centerTitle: true,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _title(isAr ? 'عام' : 'General'),

                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.language_rounded,
                      color: colors.primary,
                    ),
                    title: Text(AppStrings.tr('language')),
                    subtitle: Text(AppLanguageManager.currentDisplayName),
                    trailing: Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                    ),
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.language);
                      if (mounted) setState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: colors.primary,
                    ),
                    title: Text(AppStrings.tr('theme')),
                    subtitle: Text(
                      AppStrings.tr(AppThemeManager.currentLabelKey),
                    ),
                    trailing: Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                    ),
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.theme);
                      if (mounted) setState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 20),

                _title(isAr ? 'عن التطبيق' : 'About'),

                Card(
                  child: ListTile(
                    leading: Icon(Icons.info_rounded, color: colors.primary),
                    title: Text(isAr ? 'عن تطبيق خِدْمَة' : 'About Khidma'),
                    subtitle: Text(
                      isAr ? 'الإصدار 1.0.0' : 'Version 1.0.0',
                    ),
                    trailing: Icon(
                      isRtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Khidma - خِدْمَة',
                        applicationVersion: '1.0.0',
                        applicationLegalese: isAr
                            ? 'منصة الخدمات المنزلية الذكية'
                            : 'Smart Home Services Platform',
                      );
                    },
                  ),
                ),
              ],
            ),
          );
      },
    );
  }

  Widget _title(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }
}
