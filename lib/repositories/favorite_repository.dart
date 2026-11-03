import 'package:flutter/foundation.dart';
import '../data/user_session.dart';
import '../services/firestore_service.dart';
import '../services/sqlite_service.dart';

/// Favorite Repository
/// مسؤولة عن إدارة المفضلة وتخزينها محلياً في SQLite مع مزامنة خفيفة سحابية مع Firestore
/// وتحديث الواجهات بشكل لحظي وفوري عبر favoritesNotifier.
class FavoriteRepository {
  /// نوتيفاير عام لحظي لإشعار كافة الواجهات عند إضافة أو حذف أي عنصر من المفضلة
  static final ValueNotifier<List<String>> favoritesNotifier =
      ValueNotifier<List<String>>([]);

  /// تهيئة المفضلة من SQLite محلياً ومزامنتها مع Firestore
  static Future<void> init() async {
    // 1. قراءة سريعة فورية من SQLite محلياً (0ms)
    final dbRows = await SqliteService.getFavorites();
    final localFavorites = dbRows
        .map((r) => r['targetId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    favoritesNotifier.value = localFavorites.toList();

    // 2. مزامنة خفيفة مع Firestore إذا كان المستخدم مسجلاً
    final userId = UserSession.currentUser.id;
    if (userId.isNotEmpty && userId != 'client_guest') {
      try {
        final remoteFavs = await FirestoreService.getFavorites(userId);
        bool hasChanges = false;
        for (final favId in remoteFavs) {
          if (!localFavorites.contains(favId)) {
            localFavorites.add(favId);
            await SqliteService.insertFavorite(
              targetId: favId,
              type: 'item',
              title: favId,
            );
            hasChanges = true;
          }
        }
        if (hasChanges) {
          favoritesNotifier.value = localFavorites.toList();
        }

        // مزامنة العناصر المحلية للسحابة إن كان في المحلي عناصر غير موجودة بالسحاب
        if (localFavorites.length > remoteFavs.length) {
          await FirestoreService.syncFavorites(userId, localFavorites.toList());
        }
      } catch (e) {
        debugPrint('Error syncing favorites with Firestore: $e');
      }
    }
  }

  List<String> getFavorites() {
    return favoritesNotifier.value;
  }

  bool isFavorite(String id) {
    return favoritesNotifier.value.contains(id);
  }

  Future<void> toggleFavorite(
    String id, {
    String type = 'service',
    String title = '',
  }) async {
    final willAdd = !isFavorite(id);
    if (willAdd) {
      await addFavorite(id, type: type, title: title);
    } else {
      await removeFavorite(id, type);
    }
  }

  Future<void> addFavorite(
    String id, {
    String type = 'service',
    String title = '',
  }) async {
    final current = Set<String>.from(favoritesNotifier.value);
    if (!current.contains(id)) {
      current.add(id);
      favoritesNotifier.value = current.toList();

      // حفظ محلي في SQLite
      await SqliteService.insertFavorite(
        targetId: id,
        type: type,
        title: title.isNotEmpty ? title : id,
      );

      // مزامنة خفيفة مع Firestore
      _syncToCloud();
    }
  }

  Future<void> removeFavorite(String id, [String? type]) async {
    final current = Set<String>.from(favoritesNotifier.value);
    if (current.contains(id)) {
      current.remove(id);
      favoritesNotifier.value = current.toList();

      // حذف محلي من SQLite
      await SqliteService.deleteFavorite(id, type);

      // مزامنة خفيفة مع Firestore
      _syncToCloud();
    }
  }

  static void _syncToCloud() {
    final userId = UserSession.currentUser.id;
    if (userId.isNotEmpty && userId != 'client_guest') {
      FirestoreService.syncFavorites(userId, favoritesNotifier.value);
    }
  }

  Future<List<Map<String, dynamic>>> getFavoritesFromDb({String? type}) async {
    return await SqliteService.getFavorites(type: type);
  }
}
