import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  String? selectedMethod;

  // أسماء محافظ الدفع (جيب، جوالي، الكريمي، فلوسك) علامات تجارية لا تُترجم،
  // ويُترجم فقط وصف "الدفع عند إتمام الخدمة". القائمة getter حتى تُترجم عند
  // كل بناء فتتبع لغة التطبيق الحالية.
  List<(String, IconData)> get methods => [
    (
      AppStrings.t('الدفع عند إتمام الخدمة', 'Pay after service completion'),
      Icons.handshake_outlined,
    ),
    ('جيب', Icons.account_balance_wallet_outlined),
    ('جوالي', Icons.phone_android_rounded),
    ('الكريمي', Icons.account_balance_outlined),
    ('فلوسك', Icons.payments_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('طريقة الدفع', 'Payment Method')),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('المبلغ المقدر', 'Estimated amount'),
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 5),

              Text(
                AppStrings.t('حسب الاتفاق المباشر', 'By direct agreement'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                AppStrings.t(
                  'اختر طريقة الدفع المفضلة',
                  'Choose your preferred payment method',
                ),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    final method = methods[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedMethod = method.$1;
                          });
                        },
                        leading: Icon(method.$2, color: colors.primary),
                        title: Text(
                          method.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Radio<String>(
                          value: method.$1,
                          // ignore: deprecated_member_use
                          groupValue: selectedMethod,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              selectedMethod = value!;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.orderSuccess,
                      arguments: selectedMethod ?? methods.first.$1,
                    );
                  },
                  child: Text(
                    AppStrings.t('تأكيد طريقة الدفع', 'Confirm Payment Method'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
