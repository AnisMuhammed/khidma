import 'package:flutter/foundation.dart';
import '../services/local_db_service.dart';
import '../services/sqlite_service.dart';

/// Favorite Repository
/// مسؤولة عن إدارة المفضلة وتخزينها في قاعدة البيانات المحلية (SQLite + SharedPreferences)
/// وتحديث الواجهات بشكل لحظي وفوري عبر favoritesNotifier.
class FavoriteRepository {
  /// نوتيفاير عام لحظي لإشعار كافة الواجهات عند إضافة أو حذف أي عنصر من المفضلة
  static final ValueNotifier<List<String>> favoritesNotifier =
      ValueNotifier<List<String>>([]);

  /// تهيئة المفضلة ومزامنة البيانات بين SharedPreferences و SQLite
  static Future<void> init() async {
    final localList = LocalDbService.getFavorites();
    favoritesNotifier.value = List<String>.from(localList);
    await _syncWithDb();
  }

  static Future<void> _syncWithDb() async {
    try {
      final dbFavs = await SqliteService.getFavorites();
      final current = Set<String>.from(LocalDbService.getFavorites());
      for (final row in dbFavs) {
        final tid = row['targetId']?.toString();
        if (tid != null && tid.isNotEmpty) {
          current.add(tid);
        }
      }
      for (final id in current) {
        await LocalDbService.addFavorite(id);
      }
      favoritesNotifier.value = current.toList();
    } catch (_) {}
  }

  List<String> getFavorites() {
    return favoritesNotifier.value.isNotEmpty
        ? favoritesNotifier.value
        : LocalDbService.getFavorites();
  }

  bool isFavorite(String id) {
    return favoritesNotifier.value.contains(id) ||
        LocalDbService.getFavorites().contains(id);
  }

  Future<void> toggleFavorite(
    String id, {
    String type = 'service',
    String title = '',
  }) async {
    final willAdd = !isFavorite(id);
    await LocalDbService.toggleFavorite(id);
    if (willAdd) {
      await SqliteService.insertFavorite(
        targetId: id,
        type: type,
        title: title.isNotEmpty ? title : id,
      );
    } else {
      await SqliteService.deleteFavorite(id, type);
    }
    // تحديث النوتيفاير فوراً لإشعار كل الشاشات المفتوحة
    favoritesNotifier.value = List<String>.from(LocalDbService.getFavorites());
  }

  Future<void> addFavorite(
    String id, {
    String type = 'service',
    String title = '',
  }) async {
    await LocalDbService.addFavorite(id);
    await SqliteService.insertFavorite(
      targetId: id,
      type: type,
      title: title.isNotEmpty ? title : id,
    );
    favoritesNotifier.value = List<String>.from(LocalDbService.getFavorites());
  }

  Future<void> removeFavorite(String id, [String? type]) async {
    await LocalDbService.removeFavorite(id);
    await SqliteService.deleteFavorite(id, type);
    favoritesNotifier.value = List<String>.from(LocalDbService.getFavorites());
  }

  Future<List<Map<String, dynamic>>> getFavoritesFromDb({String? type}) async {
    return await SqliteService.getFavorites(type: type);
  }
}
