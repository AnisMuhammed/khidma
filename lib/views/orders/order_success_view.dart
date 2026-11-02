import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class OrderSuccessView extends StatelessWidget {
  const OrderSuccessView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final arguments =
        ModalRoute.of(context)?.settings.arguments;

    String paymentMethod = AppStrings.t('غير محددة', 'Not specified');

    if (arguments is String && arguments.isNotEmpty) {
      paymentMethod = arguments;
    }

    return PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(
                        alpha: 0.12,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 70,
                      color: colors.primary,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    AppStrings.t(
                      'تم إنشاء الطلب بنجاح ',
                      'Order created successfully ',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    AppStrings.t(
                      'تم تسجيل طلبك بنجاح، ويمكنك متابعة تفاصيل الطلب والتواصل مع مزود الخدمة.',
                      'Your order was registered successfully. You can track its details and contact the service provider.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment_rounded,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${AppStrings.t('طريقة الدفع', 'Payment method')}: $paymentMethod',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.main,
                              (route) => false,
                        );
                      },
                      child: Text(
                        AppStrings.t('العودة للرئيسية', 'Back to Home'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.orders,
                              (route) => false,
                        );
                      },
                      child: Text(
                        AppStrings.t('عرض طلباتي', 'View My Orders'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}