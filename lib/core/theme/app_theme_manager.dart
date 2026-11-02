import 'package:flutter/material.dart';
import '../../services/local_db_service.dart';

class AppThemeManager {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  static void init() {
    final saved = LocalDbService.getSavedTheme();
    switch (saved) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  static Future<void> changeTheme(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    String str = 'system';
    if (mode == ThemeMode.light) str = 'light';
    if (mode == ThemeMode.dark) str = 'dark';
    await LocalDbService.saveTheme(str);
  }

  /// مفتاح ترجمة وضع المظهر الحالي (يُترجم عبر AppStrings.tr).
  static String get currentLabelKey {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return 'light_theme';
      case ThemeMode.dark:
        return 'dark_theme';
      default:
        return 'system_theme';
    }
  }
}
