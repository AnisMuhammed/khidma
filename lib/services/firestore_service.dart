import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/category_helper.dart';
import '../models/order_model.dart';
import '../models/provider_model.dart';
import '../models/rating_model.dart';
import '../models/user_model.dart';
import 'sqlite_service.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _usersRef => _firestore.collection('users');
  static CollectionReference get _providersRef =>
      _firestore.collection('providers');
  static CollectionReference get _ordersRef => _firestore.collection('orders');
  static CollectionReference get _reviewsRef =>
      _firestore.collection('reviews');

  // ============================================================
  // المستخدمين (Users)
  // ============================================================

  static Future<void> saveUser(UserModel user) async {
    try {
      await _usersRef.doc(user.id).set({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
        'profileImagePath': user.profileImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // حفظ نسخة في SQLite محلياً
      await SqliteService.insertUser(user);
    } catch (e) {
      debugPrint('Firestore saveUser error: $e');
      // الاستمرار بحفظه في SQLite محلياً في حال عدم وجود إنترنت
      await SqliteService.insertUser(user);
    }
  }

  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final user = UserModel(
          id: data['id']?.toString() ?? uid,
          name: data['name']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          role: data['role']?.toString() ?? 'client',
          profileImagePath: data['profileImagePath']?.toString(),
        );
        await SqliteService.insertUser(user);
        return user;
      }
    } catch (e) {
      debugPrint('Firestore getUser error: $e');
    }
    // جلب من SQLite كاش
    return await SqliteService.getUser(uid);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final snap = await _usersRef
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data() as Map<String, dynamic>;
        final user = UserModel(
          id: data['id']?.toString() ?? snap.docs.first.id,
          name: data['name']?.toString() ?? '',
          email: data['email']?.toString() ?? cleanEmail,
          phone: data['phone']?.toString() ?? '',
          role: data['role']?.toString() ?? 'client',
          profileImagePath: data['profileImagePath']?.toString(),
        );
        await SqliteService.insertUser(user);
        return user;
      }
    } catch (e) {
      debugPrint('Firestore getUserByEmail error: $e');
    }
    // جلب من SQLite كاش
    return await SqliteService.getUserByEmail(cleanEmail);
  }

  // ============================================================
  // مزودو الخدمة (Providers)
  // ============================================================

  static Future<void> saveProvider(ProviderModel provider) async {
    try {
      final works = provider.previousWorks.map((w) {
        return {
          'title': w.title,
          'description': w.description,
          'beforeImagePath': w.beforeImagePath,
          'afterImagePath': w.afterImagePath,
        };
      }).toList();

      await _providersRef.doc(provider.id).set({
        'id': provider.id,
        'name': provider.name,
        'profession': provider.profession,
        'serviceCategory': provider.serviceCategory,
        'experienceYears': provider.experienceYears,
        'rating': provider.rating,
        'completedJobs': provider.completedJobs,
        'reviewsCount': provider.reviewsCount,
        'bio': provider.bio,
        'isVerified': provider.isVerified,
        'isAvailable': provider.isAvailable,
        'certificates': provider.certificates,
        'previousWorks': works,
        'availableDays': provider.availableDays,
        'startTime': provider.startTime,
        'endTime': provider.endTime,
        'phone': provider.phone,
        'email': provider.email,
        'profileImagePath': provider.profileImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // كاش في SQLite
      await SqliteService.insertOrUpdateProvider(provider);
    } catch (e) {
      debugPrint('Firestore saveProvider error: $e');
      await SqliteService.insertOrUpdateProvider(provider);
    }
  }

  static Future<List<ProviderModel>> getProviders({String? category}) async {
    try {
      final snapshot = await _providersRef.get();
      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final m = doc.data() as Map<String, dynamic>;
          final prov = _mapToProvider(m, doc.id);
          // حفظ في الكاش المحلي
          SqliteService.insertOrUpdateProvider(prov);
          return prov;
        }).toList();

        if (category != null && category.trim().isNotEmpty) {
          return list
              .where(
                (p) => CategoryHelper.matchesCategory(
                  providerProfession: p.profession,
                  providerCategory: p.serviceCategory,
                  targetCategory: category,
                ),
              )
              .toList();
        }

        return list;
      }
    } catch (e) {
      debugPrint('Firestore getProviders error: $e');
    }

    // جلب من SQLite عند عدم توفر اتصال
    return await SqliteService.getProviders(category: category);
  }

  static Future<ProviderModel?> getProviderById(String id) async {
    try {
      final doc = await _providersRef.doc(id).get();
      if (doc.exists && doc.data() != null) {
        final m = doc.data() as Map<String, dynamic>;
        final prov = _mapToProvider(m, doc.id);
        await SqliteService.insertOrUpdateProvider(prov);
        return prov;
      }
    } catch (e) {
      debugPrint('Firestore getProviderById error: $e');
    }
    return await SqliteService.getProviderById(id);
  }

  static Future<ProviderModel?> getProviderByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final snap = await _providersRef
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data() as Map<String, dynamic>;
        final prov = _mapToProvider(data, snap.docs.first.id);
        await SqliteService.insertOrUpdateProvider(prov);
        return prov;
      }
    } catch (e) {
      debugPrint('Firestore getProviderByEmail error: $e');
    }
    return await SqliteService.getProviderByEmail(cleanEmail);
  }

  static ProviderModel _mapToProvider(
    Map<String, dynamic> m,
    String defaultId,
  ) {
    List<PreviousWork> previousWorks = [];
    if (m['previousWorks'] is List) {
      previousWorks = (m['previousWorks'] as List).map((w) {
        final item = w as Map<String, dynamic>;
        return PreviousWork(
          title: item['title']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          beforeImagePath: item['beforeImagePath']?.toString(),
          afterImagePath: item['afterImagePath']?.toString(),
        );
      }).toList();
    }

    List<String> certificates = [];
    if (m['certificates'] is List) {
      certificates = (m['certificates'] as List)
          .map((e) => e.toString())
          .toList();
    }

    Map<String, bool> availableDays = {};
    if (m['availableDays'] is Map) {
      availableDays = (m['availableDays'] as Map).map(
        (k, v) => MapEntry(k.toString(), v == true),
      );
    }

    return ProviderModel(
      id: m['id']?.toString() ?? defaultId,
      name: m['name']?.toString() ?? '',
      profession: m['profession']?.toString() ?? '',
      serviceCategory: m['serviceCategory']?.toString() ?? '',
      experienceYears: (m['experienceYears'] as num?)?.toInt() ?? 0,
      rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
      completedJobs: (m['completedJobs'] as num?)?.toInt() ?? 0,
      reviewsCount: (m['reviewsCount'] as num?)?.toInt() ?? 0,
      bio: m['bio']?.toString() ?? '',
      isVerified: m['isVerified'] == true,
      isAvailable: m['isAvailable'] != false,
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
  // الطلبات (Orders)
  // ============================================================

  static Future<void> createOrder(OrderModel order) async {
    try {
      await _ordersRef.doc(order.id).set({
        ...order.toJson(),
        'clientId': order.clientId,
        'providerId': order.providerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // حفظ نسخة في SQLite
      await SqliteService.insertOrder(order);
    } catch (e) {
      debugPrint('Firestore createOrder error: $e');

      // الاستمرار محلياً عند عدم وجود إنترنت
      await SqliteService.insertOrder(order);
    }
  }

  static Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      await _ordersRef.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await SqliteService.updateOrderStatus(
        orderId,
        status,
      );
    } catch (e) {
      debugPrint('Firestore updateOrderStatus error: $e');

      await SqliteService.updateOrderStatus(
        orderId,
        status,
      );
    }
  }

  /// جلب طلبات العميل باستخدام clientId
  static Future<List<OrderModel>> getOrdersForClient(
    String clientId,
  ) async {
    try {
      final snapshot = await _ordersRef
          .where(
            'clientId',
            isEqualTo: clientId,
          )
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data =
              doc.data() as Map<String, dynamic>;

          final order = OrderModel.fromJson({
            ...data,
            'id': data['id'] ?? doc.id,
          });

          // تحديث الكاش المحلي
          SqliteService.insertOrder(order);

          return order;
        }).toList();

        return list;
      }
    } catch (e) {
      debugPrint(
        'Firestore getOrdersForClient error: $e',
      );
    }

    // في حالة عدم وجود اتصال أو عدم وجود بيانات
    return await SqliteService.getOrdersForClient(
      clientId,
    );
  }

  /// جلب طلبات مزود الخدمة باستخدام providerId
  static Future<List<OrderModel>> getOrdersForProvider(
    String providerId,
  ) async {
    try {
      final snapshot = await _ordersRef
          .where(
            'providerId',
            isEqualTo: providerId,
          )
          .get();

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data =
              doc.data() as Map<String, dynamic>;

          final order = OrderModel.fromJson({
            ...data,
            'id': data['id'] ?? doc.id,
          });

          // تحديث الكاش المحلي
          SqliteService.insertOrder(order);

          return order;
        }).toList();

        return list;
      }
    } catch (e) {
      debugPrint(
        'Firestore getOrdersForProvider error: $e',
      );
    }

    // في حالة عدم وجود اتصال أو عدم وجود بيانات
    return await SqliteService.getOrdersForProvider(
      providerId,
    );
  }
  // ============================================================
  // التقييمات (Reviews)
  // ============================================================

  static Future<void> addReview(RatingModel review) async {
    try {
      await _reviewsRef.add({
        'orderId': review.orderId,
        'providerId': review.providerId,
        'clientName': review.clientName,
        'rating': review.rating,
        'comment': review.comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore addReview error: $e');
    }
  }
}
