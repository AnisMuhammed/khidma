import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/order_model.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../../core/utils/app_image_helper.dart';

/// OrdersView (MVVM)
/// View -> OrderViewModel -> OrderRepository -> Remote DB
class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  late final OrderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OrderViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadOrders();
    });
  }

  Future<void> _refresh() async {
    await _viewModel.loadOrders();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: AppLanguageManager.localeNotifier,
      builder: (context, locale, _) {
        final isAr = AppLanguageManager.isArabic;

        return Scaffold(
            appBar: AppBar(
              title: Text(AppStrings.tr('orders')),
              centerTitle: true,
              leading: Navigator.canPop(context)
                  ? const BackButton()
                  : (ModalRoute.of(context)?.settings.name == AppRoutes.orders
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: isAr ? 'الرئيسية' : 'Home',
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.main,
                              (r) => false,
                            ),
                          )
                        : null),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: isAr ? 'تحديث' : 'Refresh',
                  onPressed: _refresh,
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _refresh,
              child: ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (_viewModel.isLoading && _viewModel.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = _viewModel.orders;

                  if (orders.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 70,
                                color: colors.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isAr
                                    ? 'لا توجد طلبات حالياً'
                                    : 'No orders currently',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isAr
                                    ? 'اسحب للأسفل لتحديث القائمة'
                                    : 'Pull down to refresh list',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusColor = order.getStatusColor(colors);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    child: Icon(
                                      Icons.handyman_rounded,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.serviceName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          AppStrings.t(
                                            'المزود: ${order.providerName}',
                                            'Provider: ${order.providerName}',
                                          ),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          order.statusIcon,
                                          size: 14,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          order.statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.chat_outlined, size: 20),
                                    color: colors.primary,
                                    tooltip: AppStrings.t(
                                      'محادثة المزود',
                                      'Chat with provider',
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.chat,
                                        arguments: order,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                order.description,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${order.date} • ${order.time}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      order.notes.isNotEmpty
                                          ? order.notes
                                          : AppStrings.t(
                                              'السعر اتفاقي',
                                              'Price by agreement',
                                            ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // عرض صور قبل وبعد إن وجدت
                              if (order.beforeImagePath != null ||
                                  order.afterImagePath != null) ...[
                                const SizedBox(height: 10),
                                const Divider(),
                                Text(
                                  AppStrings.t(
                                    '📸 صور تنفيذ العمل:',
                                    '📸 Work completion photos:',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (order.beforeImagePath != null)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              AppStrings.t(
                                                'قبل العمل',
                                                'Before',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            AppImageHelper.buildImage(
                                              path: order.beforeImagePath,
                                              height: 70,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              cacheHeight:
                                                  (70 *
                                                          MediaQuery.devicePixelRatioOf(
                                                            context,
                                                          ))
                                                      .round(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (order.beforeImagePath != null &&
                                        order.afterImagePath != null)
                                      const SizedBox(width: 8),
                                    if (order.afterImagePath != null)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              AppStrings.t('بعد العمل', 'After'),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            AppImageHelper.buildImage(
                                              path: order.afterImagePath,
                                              height: 70,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              cacheHeight:
                                                  (70 *
                                                          MediaQuery.devicePixelRatioOf(
                                                            context,
                                                          ))
                                                      .round(),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],

                              // زر التقييم إذا كان الطلب مكتملاً
                              if (order.status == OrderStatus.completed) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: order.isRated
                                        ? null
                                        : () async {
                                            final rated =
                                                await Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.rating,
                                                  arguments: {
                                                    'orderId': order.id,
                                                    'providerName':
                                                        order.providerName,
                                                    'serviceName':
                                                        order.serviceName,
                                                  },
                                                );
                                            if (rated == true) {
                                              setState(() {
                                                order.isRated = true;
                                              });
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.star_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      order.isRated
                                          ? AppStrings.t(
                                              'تم التقييم بنجاح ⭐',
                                              'Rated successfully ⭐',
                                            )
                                          : AppStrings.t(
                                              'تقييم الخدمة ⭐',
                                              'Rate the service ⭐',
                                            ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: order.isRated
                                          ? Colors.grey
                                          : Colors.amber.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
      },
    );
  }
}
