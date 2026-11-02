import '../models/service_model.dart';
import '../services/api_service.dart';
import '../data/services_data.dart';

/// Service Repository (Repository Pattern)
/// مسؤولة عن جلب الخدمات وإتاحة البحث وتنسيق البيانات بين الـ API والذاكرة المحلية
class ServiceRepository {
  List<ServiceModel> _cachedServices = [];

  Future<List<ServiceModel>> getServices({bool forceRefresh = false}) async {
    if (_cachedServices.isEmpty || forceRefresh) {
      _cachedServices = await ApiService.fetchServices();
      if (_cachedServices.isEmpty) {
        _cachedServices = servicesData;
      }
    }
    return _cachedServices;
  }

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

  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    final all = await getServices();
    if (category == 'الكل' || category.isEmpty) return all;
    return all.where((s) => s.category == category).toList();
  }
}

