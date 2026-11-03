import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/categories_data.dart';
import '../data/services_data.dart';
import '../models/service_model.dart';
import '../services/firestore_service.dart';

/// Service Repository (Repository Pattern)
/// مسؤولة عن جلب الخدمات والتصنيفات ديناميكياً من Cloud Firestore أولاً،
/// مع اعتماد القوائم المضمنة كـ Fallback/Offline Cache محلي،
/// وتحديث كافة الواجهات بشكل فوري ولحظي عند إضافة أو تعديل أي خدمة سحابياً.
class ServiceRepository {
  /// نوتيفاير لحظي للخدمات (يبدأ فوراً بالبيانات المحلية 0ms ثم يتزامن سحابياً)
  static final ValueNotifier<List<ServiceModel>> servicesNotifier =
      ValueNotifier<List<ServiceModel>>(servicesData);

  /// نوتيفاير لحظي للتصنيفات (يبدأ فوراً بالبيانات المحلية 0ms ثم يتزامن سحابياً)
  static final ValueNotifier<List<ServiceCategory>> categoriesNotifier =
      ValueNotifier<List<ServiceCategory>>(serviceCategories);

  static bool _hasInitialized = false;

  /// تهيئة المزامنة السحابية للخدمات والتصنيفات
  static void init() {
    if (_hasInitialized) return;
    _hasInitialized = true;

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. الاستماع الحي للخدمات في Firestore
      firestore.collection('services').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final list = snap.docs.map((doc) {
            final data = doc.data();
            return ServiceModel.fromJson({
              ...data,
              'id': data['id'] ?? doc.id,
            });
          }).toList();
          servicesNotifier.value = list;
        }
      }, onError: (e) {
        debugPrint('Services stream error: $e');
      });

      // 2. الاستماع الحي للتصنيفات في Firestore
      firestore.collection('categories').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          final list = snap.docs.map((doc) {
            final data = doc.data();
            return ServiceCategory.fromJson(data);
          }).toList();
          categoriesNotifier.value = list;
        }
      }, onError: (e) {
        debugPrint('Categories stream error: $e');
      });
    } catch (e) {
      debugPrint('Error initializing dynamic service repository: $e');
    }
  }

  /// جلب الخدمات
  Future<List<ServiceModel>> getServices({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final remote = await FirestoreService.getServices();
      if (remote.isNotEmpty) {
        servicesNotifier.value = remote;
      }
    }
    return servicesNotifier.value;
  }

  /// جلب التصنيفات
  Future<List<ServiceCategory>> getCategories({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final remote = await FirestoreService.getCategories();
      if (remote.isNotEmpty) {
        categoriesNotifier.value = remote;
      }
    }
    return categoriesNotifier.value;
  }

  /// البحث في الخدمات
  Future<List<ServiceModel>> searchServices(String query) async {
    final all = await getServices();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all.where((service) {
      return service.name.toLowerCase().contains(q) ||
          service.category.toLowerCase().contains(q) ||
          service.description.toLowerCase().contains(q);
    }).toList();
  }

  /// تصفية الخدمات حسب التصنيف
  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    final all = await getServices();
    if (category == 'الكل' || category.isEmpty) return all;
    return all.where((s) => s.category == category).toList();
  }
}
