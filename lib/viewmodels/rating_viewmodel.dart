import 'package:flutter/material.dart';
import '../repositories/rating_repository.dart';
import '../repositories/order_repository.dart';

/// Rating ViewModel (MVVM)
/// View -> RatingViewModel -> RatingRepository -> Remote Database / Supabase
class RatingViewModel extends ChangeNotifier {
  final RatingRepository _ratingRepo = RatingRepository();
  final OrderRepository _orderRepo = OrderRepository();

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Future<bool> submitRating({
    required String orderId,
    required String providerId,
    required String clientName,
    required double rating,
    required String comment,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final success = await _ratingRepo.submitRating(
      orderId: orderId,
      providerId: providerId,
      clientName: clientName,
      rating: rating,
      comment: comment,
    );

    if (success) {
      await _orderRepo.markOrderAsRated(orderId);
    }

    _isSubmitting = false;
    notifyListeners();
    return success;
  }
}

