import 'package:flutter/material.dart';
import '../../services/local_db_service.dart';

class AppLanguageManager {
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('ar'),
  );

  static void init() {
    final saved = LocalDbService.getSavedLanguage();
    localeNotifier.value = Locale(saved);
  }

  static bool get isArabic => localeNotifier.value.languageCode == 'ar';
  static String get currentCode => localeNotifier.value.languageCode;
  static TextDirection get currentDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// الاسم الأصلي للغة الحالية، للعرض في الواجهة.
  static String get currentDisplayName => isArabic ? 'العربية' : 'English';

  static Future<void> changeLanguage(String code) async {
    if (code != 'ar' && code != 'en') return;
    localeNotifier.value = Locale(code);
    await LocalDbService.saveLanguage(code);
  }
}
