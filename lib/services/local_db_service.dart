import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local Database Service
/// مسؤولة عن إدارة قاعدة البيانات المحلية (Local Database)
/// لتخزين:
/// 1. المفضلة (Favorites)
/// 2. السلة (Cart)
/// 3. سجل البحث (Recent Searches)
/// 4. إعدادات السمة واللغة (Settings)
class LocalDbService {
  static SharedPreferences? _prefs;

  static const String _keyFavorites = 'khidma_favorites';
  static const String _keyCart = 'khidma_cart';
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

  // ==================== المفضلة (Favorites) ====================
  static List<String> getFavorites() {
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  static Future<bool> isFavorite(String id) async {
    final list = getFavorites();
    return list.contains(id);
  }

  static Future<void> toggleFavorite(String id) async {
    final list = getFavorites().toList();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(_keyFavorites, list);
  }

  static Future<void> addFavorite(String id) async {
    final list = getFavorites().toList();
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(_keyFavorites, list);
    }
  }

  static Future<void> removeFavorite(String id) async {
    final list = getFavorites().toList();
    if (list.contains(id)) {
      list.remove(id);
      await prefs.setStringList(_keyFavorites, list);
    }
  }

  // ==================== السلة (Cart) ====================
  static List<Map<String, dynamic>> getCartItems() {
    final raw = prefs.getString(_keyCart);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addToCart(Map<String, dynamic> item) async {
    final list = getCartItems();
    // تجنب التكرار بنفس المعرف إن وجد
    final existingIndex = list.indexWhere((e) => e['id'] == item['id']);
    if (existingIndex >= 0) {
      list[existingIndex] = item;
    } else {
      list.add(item);
    }
    await prefs.setString(_keyCart, jsonEncode(list));
  }

  static Future<void> removeFromCart(String itemId) async {
    final list = getCartItems();
    list.removeWhere((e) => e['id'] == itemId);
    await prefs.setString(_keyCart, jsonEncode(list));
  }

  static Future<void> clearCart() async {
    await prefs.remove(_keyCart);
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

