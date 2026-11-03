import 'package:shared_preferences/shared_preferences.dart';

/// Local DB / Preferences Service
/// مسؤولة عن إدارة التفضيلات والإعدادات المحلية السريعة (SharedPreferences):
/// 1. سجل البحث الأخير (Recent Searches)
/// 2. إعدادات المظهر واللغة (Theme & Language)
class LocalDbService {
  static SharedPreferences? _prefs;

  static const String _keyRecentSearches = 'khidma_recent_searches';
  static const String _keyThemeMode = 'khidma_theme_mode';
  static const String _keyLanguage = 'khidma_language';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalDbService must be initialized first in main().');
    }
    return _prefs!;
  }

  // ==================== سجل البحث (Recent Searches) ====================
  static List<String> getRecentSearches() {
    return prefs.getStringList(_keyRecentSearches) ??
        ['سباك', 'كهربائي', 'تنظيف', 'تكييف'];
  }

  static Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final list = getRecentSearches().toList();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 10) list.removeLast();
    await prefs.setStringList(_keyRecentSearches, list);
  }

  static Future<void> clearRecentSearches() async {
    await prefs.remove(_keyRecentSearches);
  }

  // ==================== إعدادات المظهر واللغة ====================
  static String getSavedTheme() {
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> saveTheme(String theme) async {
    await prefs.setString(_keyThemeMode, theme);
  }

  static String getSavedLanguage() {
    return prefs.getString(_keyLanguage) ?? 'ar';
  }

  static Future<void> saveLanguage(String lang) async {
    await prefs.setString(_keyLanguage, lang);
  }
}
