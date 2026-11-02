import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../repositories/service_repository.dart';
import '../services/local_db_service.dart';

/// Search ViewModel (MVVM)
/// View -> SearchViewModel -> ServiceRepository -> API / Remote DB -> ServiceModel
class SearchViewModel extends ChangeNotifier {
  final ServiceRepository _repository = ServiceRepository();

  List<ServiceModel> _results = [];
  List<ServiceModel> get results => _results;

  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  SearchViewModel() {
    loadRecentSearches();
  }

  void loadRecentSearches() {
    _recentSearches = LocalDbService.getRecentSearches();
    notifyListeners();
  }

  Future<void> search(String query) async {
    _currentQuery = query;
    _isLoading = true;
    notifyListeners();

    _results = await _repository.searchServices(query);
    if (query.trim().isNotEmpty) {
      await LocalDbService.addRecentSearch(query.trim());
      loadRecentSearches();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    await LocalDbService.clearRecentSearches();
    loadRecentSearches();
  }
}

