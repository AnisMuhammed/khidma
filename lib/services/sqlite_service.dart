import 'dart:convert';
import 'dart:io' show Platform, Directory;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utils/category_helper.dart';
import '../models/order_model.dart';
import '../models/provider_model.dart';
import '../models/user_model.dart';

class SqliteService {
  static Database? _database;

  // ============================================================
  // تهيئة قاعدة البيانات
  // ============================================================

  static Future<void> init() async {
    if (kIsWeb) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _database = await _initDatabase();
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;

    await init();

    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String dbPath;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final docDir = await getApplicationDocumentsDirectory();

      dbPath = p.join(docDir.path, 'Khidma', 'khidma_app.db');

      final dir = Directory(p.dirname(dbPath));

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      final databasesPath = await getDatabasesPath();

      dbPath = p.join(databasesPath, 'khidma_app.db');
    }

    return await openDatabase(
      dbPath,

      // ========================================================
      // Database Version 2
      // ========================================================
      version: 2,

      // ========================================================
      // Migration: Version 1 -> Version 2
      // ========================================================
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE orders ADD COLUMN clientId TEXT');

          await db.execute('ALTER TABLE orders ADD COLUMN providerId TEXT');
        }
      },

      // ========================================================
      // بعد فتح قاعدة البيانات
      // ========================================================
      onOpen: (db) async {
        // إضافة isAvailable إذا كانت قاعدة البيانات القديمة.
        //
        // كان الكود ينفّذ ALTER TABLE في كل مرة تُفتح فيها القاعدة، فإن كان العمود
        // موجوداً أصلاً رمى SQLite خطأ «duplicate column name» وابتلعه catch —
        // فكان يظهر في السجل عند كل تشغيل بلا أي فائدة، ويُهدر استعلاماً فاشلاً
        // في كل إقلاع. نفحص وجود العمود أولاً فلا نحاول الإضافة إلا إن كانت
        // ناقصة فعلاً.
        try {
          final List<Map<String, Object?>> columns = await db.rawQuery(
            'PRAGMA table_info(providers)',
          );

          final bool hasIsAvailable = columns.any(
            (column) => column['name'] == 'isAvailable',
          );

          if (!hasIsAvailable) {
            await db.execute(
              'ALTER TABLE providers ADD COLUMN isAvailable INTEGER DEFAULT 1',
            );
          }
        } catch (_) {}

        // التأكد من وجود جدول المفضلة
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS favorites (
              id TEXT PRIMARY KEY,
              targetId TEXT NOT NULL,
              type TEXT,
              title TEXT
            )
          ''');
        } catch (_) {}
      },

      // ========================================================
      // إنشاء قاعدة بيانات جديدة
      // ========================================================
      onCreate: (db, version) async {
        // ======================================================
        // جدول المستخدمين
        // ======================================================

        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT,
            role TEXT NOT NULL,
            profileImagePath TEXT,
            createdAt TEXT
          )
        ''');

        // ======================================================
        // جدول مزودي الخدمة
        // ======================================================
        await db.execute('''
          CREATE TABLE providers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            profession TEXT NOT NULL,
            serviceCategory TEXT NOT NULL,
            experienceYears INTEGER DEFAULT 0,
            rating REAL DEFAULT 5.0,
            completedJobs INTEGER DEFAULT 0,
            reviewsCount INTEGER DEFAULT 0,
            bio TEXT,
            isVerified INTEGER DEFAULT 0,
            isAvailable INTEGER DEFAULT 1,
            certificatesJson TEXT,
            previousWorksJson TEXT,
            availableDaysJson TEXT,
            startTime TEXT,
            endTime TEXT,
            phone TEXT,
            email TEXT,
            profileImagePath TEXT
          )
        ''');

        // ======================================================
        // جدول الطلبات
        // ======================================================

        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,

            clientId TEXT,
            providerId TEXT,

            clientName TEXT NOT NULL,
            providerName TEXT NOT NULL,
            serviceName TEXT NOT NULL,
            description TEXT,
            notes TEXT,
            location TEXT,
            date TEXT,
            time TEXT,
            status TEXT NOT NULL,
            isRated INTEGER DEFAULT 0,
            beforeImagePath TEXT,
            afterImagePath TEXT,
            createdAt TEXT
          )
        ''');

        // ======================================================
        // جدول الحجوزات
        // ======================================================

        await db.execute('''
          CREATE TABLE reservations (
            id TEXT PRIMARY KEY,
            clientId TEXT,
            providerId TEXT,
            providerName TEXT NOT NULL,
            serviceName TEXT NOT NULL,
            profession TEXT,
            price TEXT,
            date TEXT,
            time TEXT,
            createdAt TEXT
          )
        ''');

        // ======================================================
        // جدول المفضلة
        // ======================================================

        await db.execute('''
          CREATE TABLE favorites (
            id TEXT PRIMARY KEY,
            targetId TEXT NOT NULL,
            type TEXT,
            title TEXT
          )
        ''');
      },
    );
  }

  // ============================================================
  // المستخدمين Users
  // ============================================================

  static Future<void> insertUser(UserModel user) async {
    if (kIsWeb) return;

    final db = await database;

    await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'role': user.role,
      'profileImagePath': user.profileImagePath,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<UserModel?> getUser(String id) async {
    if (kIsWeb) return null;

    final db = await database;

    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;

    final m = maps.first;

    return UserModel(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      role: m['role']?.toString() ?? 'client',
      profileImagePath: m['profileImagePath']?.toString(),
    );
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    if (kIsWeb) return null;

    final db = await database;

    final clean = email.trim().toLowerCase();

    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [clean],
    );

    if (maps.isEmpty) return null;

    final m = maps.first;
    return UserModel(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      phone: m['phone']?.toString() ?? '',
      role: m['role']?.toString() ?? 'client',
      profileImagePath: m['profileImagePath']?.toString(),
    );
  }

  // ============================================================
  // مزودو الخدمة Providers
  // ============================================================

  static Future<void> insertOrUpdateProvider(ProviderModel provider) async {
    if (kIsWeb) return;

    final db = await database;

    final worksJson = jsonEncode(
      provider.previousWorks.map((w) {
        return {
          'title': w.title,
          'description': w.description,
          'beforeImagePath': w.beforeImagePath,
          'afterImagePath': w.afterImagePath,
        };
      }).toList(),
    );

    await db.insert('providers', {
      'id': provider.id,
      'name': provider.name,
      'profession': provider.profession,
      'serviceCategory': provider.serviceCategory,
      'experienceYears': provider.experienceYears,
      'rating': provider.rating,
      'completedJobs': provider.completedJobs,
      'reviewsCount': provider.reviewsCount,
      'bio': provider.bio,
      'isVerified': provider.isVerified ? 1 : 0,
      'isAvailable': provider.isAvailable ? 1 : 0,
      'certificatesJson': jsonEncode(provider.certificates),
      'previousWorksJson': worksJson,
      'availableDaysJson': jsonEncode(provider.availableDays),
      'startTime': provider.startTime,
      'endTime': provider.endTime,
      'phone': provider.phone,
      'email': provider.email,
      'profileImagePath': provider.profileImagePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ProviderModel>> getProviders({String? category}) async {
    if (kIsWeb) return [];

    final db = await database;

    final maps = await db.query('providers');

    final all = maps.map((m) => _mapToProvider(m)).toList();

    if (category != null && category.trim().isNotEmpty) {
      return all
          .where(
            (provider) => CategoryHelper.matchesCategory(
              providerProfession: provider.profession,
              providerCategory: provider.serviceCategory,
              targetCategory: category,
            ),
          )
          .toList();
    }

    return all;
  }

  static Future<ProviderModel?> getProviderById(String id) async {
    if (kIsWeb) return null;

    final db = await database;

    final maps = await db.query('providers', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;

    return _mapToProvider(maps.first);
  }

  static Future<ProviderModel?> getProviderByEmail(String email) async {
    if (kIsWeb) return null;

    final db = await database;

    final clean = email.trim().toLowerCase();

    final maps = await db.query(
      'providers',
      where: 'LOWER(email) = ?',
      whereArgs: [clean],
    );

    if (maps.isEmpty) return null;

    return _mapToProvider(maps.first);
  }

  static ProviderModel _mapToProvider(Map<String, dynamic> m) {
    List<PreviousWork> previousWorks = [];

    if (m['previousWorksJson'] != null) {
      try {
        final decoded = jsonDecode(m['previousWorksJson'] as String) as List;

        previousWorks = decoded.map((w) {
          final item = w as Map<String, dynamic>;

          return PreviousWork(
            title: item['title']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
            beforeImagePath: item['beforeImagePath']?.toString(),
            afterImagePath: item['afterImagePath']?.toString(),
          );
        }).toList();
      } catch (_) {}
    }

    List<String> certificates = [];
    if (m['certificatesJson'] != null) {
      try {
        final decoded = jsonDecode(m['certificatesJson'] as String) as List;

        certificates = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    Map<String, bool> availableDays = {};

    if (m['availableDaysJson'] != null) {
      try {
        final decoded = jsonDecode(m['availableDaysJson'] as String) as Map;

        availableDays = decoded.map(
          (k, v) => MapEntry(k.toString(), v == true),
        );
      } catch (_) {}
    }

    return ProviderModel(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      profession: m['profession']?.toString() ?? '',
      serviceCategory: m['serviceCategory']?.toString() ?? '',
      experienceYears: (m['experienceYears'] as num?)?.toInt() ?? 0,
      rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      completedJobs: (m['completedJobs'] as num?)?.toInt() ?? 0,
      reviewsCount: (m['reviewsCount'] as num?)?.toInt() ?? 0,
      bio: m['bio']?.toString() ?? '',
      isVerified: m['isVerified'] == 1,
      isAvailable: (m['isAvailable'] == null || m['isAvailable'] == 1),
      certificates: certificates,
      previousWorks: previousWorks,
      availableDays: availableDays,
      startTime: m['startTime']?.toString() ?? '08:00 صباحاً',
      endTime: m['endTime']?.toString() ?? '06:00 مساءً',
      phone: m['phone']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      profileImagePath: m['profileImagePath']?.toString(),
    );
  }

  // ============================================================
  // الطلبات Orders
  // ============================================================

  static Future<void> insertOrder(OrderModel order) async {
    if (kIsWeb) return;

    final db = await database;

    await db.insert('orders', {
      'id': order.id,

      // IDs
      'clientId': order.clientId,
      'providerId': order.providerId,

      // البيانات
      'clientName': order.clientName,
      'providerName': order.providerName,
      'serviceName': order.serviceName,
      'description': order.description,
      'notes': order.notes,
      'location': order.location,
      'date': order.date,
      'time': order.time,

      // الحالة
      'status': order.status.name,
      'isRated': order.isRated ? 1 : 0,

      // الصور
      'beforeImagePath': order.beforeImagePath,
      'afterImagePath': order.afterImagePath,

      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    if (kIsWeb) return;

    final db = await database;

    await db.update(
      'orders',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ============================================================
  // طلبات العميل باستخدام clientId
  // ============================================================

  static Future<List<OrderModel>> getOrdersForClient(
    String clientIdentifier,
  ) async {
    if (kIsWeb) return [];

    final db = await database;

    final maps = await db.query(
      'orders',
      where: 'clientId = ? OR clientName = ?',
      whereArgs: [clientIdentifier, clientIdentifier],
      orderBy: 'createdAt DESC',
    );

    if (maps.isEmpty) {
      return [];
    }

    return maps.map((m) => _mapToOrder(m)).toList();
  }

  // ============================================================
  // طلبات مزود الخدمة باستخدام providerId أو providerName
  // ============================================================

  static Future<List<OrderModel>> getOrdersForProvider(
    String providerIdentifier,
  ) async {
    if (kIsWeb) return [];
    final db = await database;

    final maps = await db.query(
      'orders',
      where: 'providerId = ? OR providerName = ?',
      whereArgs: [providerIdentifier, providerIdentifier],
      orderBy: 'createdAt DESC',
    );

    if (maps.isEmpty) {
      return [];
    }

    return maps.map((m) => _mapToOrder(m)).toList();
  }

  static Future<List<OrderModel>> getAllOrders() async {
    if (kIsWeb) return [];

    final db = await database;

    final maps = await db.query('orders', orderBy: 'createdAt DESC');

    return maps.map((m) => _mapToOrder(m)).toList();
  }

  static OrderModel _mapToOrder(Map<String, dynamic> m) {
    return OrderModel(
      id: m['id']?.toString() ?? '',

      clientId: m['clientId']?.toString() ?? '',

      providerId: m['providerId']?.toString() ?? '',

      clientName: m['clientName']?.toString() ?? '',

      providerName: m['providerName']?.toString() ?? '',

      serviceName: m['serviceName']?.toString() ?? '',

      description: m['description']?.toString() ?? '',

      notes: m['notes']?.toString() ?? '',

      location: m['location']?.toString() ?? '',

      date: m['date']?.toString() ?? '',

      time: m['time']?.toString() ?? '',

      status: OrderStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => OrderStatus.pending,
      ),

      isRated: m['isRated'] == 1,

      beforeImagePath: m['beforeImagePath']?.toString(),

      afterImagePath: m['afterImagePath']?.toString(),
    );
  }

  // ============================================================
  // الحجوزات Reservations
  // ============================================================

  static Future<void> addReservation(Map<String, dynamic> res) async {
    if (kIsWeb) return;

    final db = await database;

    await db.insert('reservations', {
      'id': res['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),

      'clientId': res['clientId'],

      'providerId': res['providerId'],

      'providerName': res['providerName'] ?? '',

      'serviceName': res['serviceName'] ?? '',

      'profession': res['profession'] ?? '',

      'price': res['price'] ?? 'حسب الاتفاق',

      'date': res['date'] ?? '',

      'time': res['time'] ?? '',

      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getReservations(
    String? clientId,
  ) async {
    if (kIsWeb) return [];

    final db = await database;

    if (clientId != null && clientId.isNotEmpty) {
      return await db.query(
        'reservations',
        where: 'clientId = ?',
        whereArgs: [clientId],
        orderBy: 'createdAt DESC',
      );
    }

    return await db.query('reservations', orderBy: 'createdAt DESC');
  }

  static Future<void> removeReservation(String id) async {
    if (kIsWeb) return;

    final db = await database;

    await db.delete('reservations', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearReservations() async {
    if (kIsWeb) return;

    final db = await database;

    await db.delete('reservations');
  }

  // ============================================================
  // المفضلة Favorites
  // ============================================================

  static Future<void> insertFavorite({
    required String targetId,
    required String type,
    required String title,
  }) async {
    if (kIsWeb) return;

    final db = await database;

    await db.insert('favorites', {
      'id': '$type-$targetId',
      'targetId': targetId,
      'type': type,
      'title': title,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteFavorite(String targetId, [String? type]) async {
    if (kIsWeb) return;

    final db = await database;

    if (type != null) {
      await db.delete(
        'favorites',
        where: 'targetId = ? AND type = ?',
        whereArgs: [targetId, type],
      );
    } else {
      await db.delete(
        'favorites',
        where: 'targetId = ? OR id = ?',
        whereArgs: [targetId, targetId],
      );
    }
  }

  static Future<bool> isFavorite(String targetId) async {
    if (kIsWeb) return false;

    final db = await database;

    final res = await db.query(
      'favorites',
      where: 'targetId = ? OR id = ?',
      whereArgs: [targetId, targetId],
    );

    return res.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getFavorites({String? type}) async {
    if (kIsWeb) return [];

    final db = await database;

    if (type != null) {
      return await db.query('favorites', where: 'type = ?', whereArgs: [type]);
    }

    return await db.query('favorites');
  }
}
