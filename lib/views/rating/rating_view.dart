import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../data/user_session.dart';
import '../../viewmodels/rating_viewmodel.dart';

class RatingView extends StatefulWidget {
  const RatingView({super.key});

  @override
  State<RatingView> createState() => _RatingViewState();
}

class _RatingViewState extends State<RatingView> {
  int rating = 5;
  final commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final args = ModalRoute.of(context)?.settings.arguments;
    String providerName = 'أحمد محمد';
    String serviceName = 'سباك محترف';
    String orderId = 'ORD-1';
    String providerId = 'PRV-1';

    if (args is Map<String, dynamic>) {
      providerName = args['providerName']?.toString() ?? providerName;
      serviceName = args['serviceName']?.toString() ?? serviceName;
      orderId = args['orderId']?.toString() ?? orderId;
      providerId = args['providerId']?.toString() ?? providerId;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.tr('rate_service')),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                providerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                serviceName,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 15),
              ),

              const SizedBox(height: 30),

              Text(
                AppStrings.t('كيف كانت تجربتك؟', 'How was your experience?'),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;

                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = value;
                      });
                    },
                    icon: Icon(
                      value <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 42,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: AppStrings.t('اكتب تعليقك', 'Write your comment'),
                  hintText: AppStrings.t(
                    'شاركنا رأيك عن أداء وجودة الخدمة...',
                    'Tell us what you think about the service quality...',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() {
                            _isSubmitting = true;
                          });

                          final clientName =
                              UserSession.currentUser.name.isNotEmpty
                              ? UserSession.currentUser.name
                              : AppStrings.t('عميل خِدْمَة', 'Khidma Client');

                          await RatingViewModel().submitRating(
                            orderId: orderId,
                            providerId: providerId,
                            clientName: clientName,
                            rating: rating.toDouble(),
                            comment: commentController.text.trim(),
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.t(
                                  'شكراً لك، تم إرسال تقييمك وحفظه بنجاح',
                                  'Thank you, your rating was submitted and saved successfully',
                                ),
                              ),
                            ),
                          );

                          Navigator.pop(context, true);
                        },
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          AppStrings.t('إرسال التقييم', 'Submit Rating'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
