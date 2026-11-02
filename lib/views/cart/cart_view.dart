import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/cart_viewmodel.dart';

/// CartView (MVVM) - حجوزاتي المحفوظة للرجوع إليها لاحقاً
/// View -> CartViewModel -> CartRepository -> Local Database (SQLite / SharedPreferences)
class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  late final CartViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CartViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('حجوزاتي المحفوظة', 'My Saved Bookings')),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: AppStrings.t('حذف الكل', 'Delete all'),
              onPressed: () {
                _viewModel.clearAll();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppStrings.t(
                        'تم حذف جميع الحجوزات المحفوظة',
                        'All saved bookings were deleted',
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.itemCount == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bookmark_outline_rounded,
                          size: 45,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.t(
                          'لا توجد حجوزات محفوظة حالياً',
                          'No saved bookings yet',
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.t(
                          'عند تصفح أي مزود خدمة والضغط على "حجز لاحقاً"، سيُحفظ هنا للرجوع إليه في أي وقت.',
                          'When you browse any service provider and tap "Book Later", it will be saved here so you can come back to it anytime.',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: colors.primary.withValues(alpha: 0.06),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.t(
                            'قائمة بالخدمات المحفوظة للرجوع إليها لاحقاً (السعر اتفاقي مع المزود)',
                            'A list of saved services to come back to later (price is agreed with the provider)',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _viewModel.itemCount,
                    itemBuilder: (context, index) {
                      final item = _viewModel.items[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.bookmark_rounded,
                              color: colors.primary,
                            ),
                          ),
                          title: Text(
                            item['title'] ?? item['serviceName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${AppStrings.t('المزود', 'Provider')}: ${item['providerName'] ?? ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.tonal(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.booking,
                                    arguments: {
                                      'providerName':
                                          item['providerName'] ??
                                          AppStrings.t(
                                            'مزود خدمة',
                                            'Service Provider',
                                          ),
                                      'serviceName':
                                          item['serviceName'] ??
                                          item['title'] ??
                                          '',
                                    },
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                child: Text(
                                  AppStrings.t('طلب الآن', 'Book Now'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _viewModel.removeItem(item['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
  }
}
