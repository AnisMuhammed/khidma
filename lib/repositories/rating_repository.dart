import '../models/rating_model.dart';
import '../services/firestore_service.dart';

/// Rating Repository
/// مسؤولة عن إرسال تقييمات العملاء وحفظها في Remote Database
class RatingRepository {
  Future<bool> submitRating({
    required String orderId,
    required String providerId,
    required String clientName,
    required double rating,
    required String comment,
  }) async {
    final ratingModel = RatingModel(
      id: 'RAT-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      providerId: providerId,
      clientName: clientName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await FirestoreService.addReview(ratingModel);
      return true;
    } catch (_) {
      return false;
    }
  }
}

