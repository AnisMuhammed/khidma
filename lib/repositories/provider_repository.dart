import '../models/provider_model.dart';
import '../services/firestore_service.dart';

class ProviderRepository {
  Future<List<ProviderModel>> getProviders({String? category}) async {
    return await FirestoreService.getProviders(category: category);
  }

  Future<ProviderModel?> getProviderById(String id) async {
    return await FirestoreService.getProviderById(id);
  }

  Future<void> saveProvider(ProviderModel provider) async {
    await FirestoreService.saveProvider(provider);
  }
}
