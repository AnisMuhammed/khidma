import 'package:flutter/material.dart';
import '../repositories/favorite_repository.dart';

/// Favorite ViewModel (MVVM)
/// View -> FavoriteViewModel -> FavoriteRepository -> Local Database
class FavoriteViewModel extends ChangeNotifier {
  final FavoriteRepository _repository = FavoriteRepository();

  List<String> get favoriteIds =>
      FavoriteRepository.favoritesNotifier.value.isNotEmpty
          ? FavoriteRepository.favoritesNotifier.value
          : _repository.getFavorites();

  FavoriteViewModel() {
    FavoriteRepository.favoritesNotifier.addListener(_onFavoritesChanged);
  }

  void _onFavoritesChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    FavoriteRepository.favoritesNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void loadFavorites() {
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _repository.isFavorite(id);
  }

  Future<void> toggleFavorite(
    String id, {
    String type = 'service',
    String title = '',
  }) async {
    await _repository.toggleFavorite(id, type: type, title: title);
  }

  Future<void> removeFavorite(String id, [String? type]) async {
    await _repository.removeFavorite(id, type);
  }
}
