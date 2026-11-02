// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';

class LanguageView extends StatefulWidget {
  const LanguageView({super.key});

  @override
  State<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> {
  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = AppLanguageManager.currentCode;
  }

  Future<void> _onLanguageSelected(String? value) async {
    if (value == null) return;
    setState(() {
      selectedLanguage = value;
    });
    await AppLanguageManager.changeLanguage(value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value == 'ar'
              ? 'تم تغيير لغة التطبيق إلى العربية بنجاح'
              : 'App language changed to English successfully',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        // عنوان الشاشة يتبع اللغة الحالية فعلياً (لا لغة العنصر المختار).
        final title = AppStrings.tr('language');

        return Scaffold(
            appBar: AppBar(title: Text(title), centerTitle: true),
            body: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // اسم كل لغة يُعرض بلغتها الأصلية (اصطلاح متّبع في كل التطبيقات)،
                // لذلك تبقى هذي النصوص كما هي ولا تُترجم.
                RadioListTile<String>(
                  title: const Text('العربية (Arabic)'),
                  subtitle: const Text('اللغة العربية'),
                  value: 'ar',
                  groupValue: selectedLanguage,
                  onChanged: _onLanguageSelected,
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: const Text('English (الإنجليزية)'),
                  subtitle: const Text('English language'),
                  value: 'en',
                  groupValue: selectedLanguage,
                  onChanged: _onLanguageSelected,
                ),
              ],
            ),
          );
      },
    );
  }
}
