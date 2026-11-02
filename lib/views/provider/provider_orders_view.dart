import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/localization/app_strings.dart';
import '../../data/orders_data.dart';
import '../../models/order_model.dart';
import '../../viewmodels/order_viewmodel.dart';

class ProviderOrdersView extends StatefulWidget {
  const ProviderOrdersView({super.key});

  @override
  State<ProviderOrdersView> createState() => _ProviderOrdersViewState();
}

class _ProviderOrdersViewState extends State<ProviderOrdersView> {
  List<OrderModel> get _orders => providerOrdersData;

  void _updateOrderStatus(OrderModel order, OrderStatus newStatus) async {
    setState(() {
      order.status = newStatus;
    });
    await OrderViewModel().updateStatus(order.id, newStatus);
  }

  Future<void> _uploadWorkPhoto(OrderModel order) async {
    final picker = ImagePicker();
    final option = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppStrings.t('إرفاق صورة العمل', 'Attach work photo')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'before'),
            child: Text(
              AppStrings.t('📸 صورة قبل العمل', '📸 Before work photo'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'after'),
            child: Text(
              AppStrings.t('📸 صورة بعد العمل', '📸 After work photo'),
            ),
          ),
        ],
      ),
    );

    if (option == null || !mounted) return;

    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final isBefore = option == 'before';
      await OrderViewModel().attachWorkImage(
        orderId: order.id,
        imagePath: picked.path,
        isBefore: isBefore,
      );
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBefore
                  ? AppStrings.t(
                      'تم حفظ صورة قبل العمل',
                      'Before work photo was saved',
                    )
                  : AppStrings.t(
                      'تم حفظ صورة بعد العمل',
                      'After work photo was saved',
                    ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.t('إدارة الطلبات', 'Order Management')),
            bottom: TabBar(
              tabs: [
                Tab(text: AppStrings.t('جديدة', 'New')),
                Tab(text: AppStrings.t('قيد التنفيذ', 'In progress')),
                Tab(text: AppStrings.t('مكتملة', 'Completed')),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildPendingTab(),
              _buildInProgressTab(),
              _buildCompletedTab(),
            ],
          ),
        ),
      );
  }

  Widget _buildPendingTab() {
    final pendingOrders = _orders
        .where((o) => o.status == OrderStatus.pending)
        .toList();
    if (pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('لا توجد طلبات جديدة', 'No new orders'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingOrders.length,
      itemBuilder: (context, index) {
        final order = pendingOrders[index];
        return _OrderCard(
          order: order,
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppStrings.t('رفض الطلب', 'Reject Order')),
                      content: Text(
                        AppStrings.t(
                          'هل أنت متأكد من رفض هذا الطلب؟',
                          'Are you sure you want to reject this order?',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppStrings.t('تراجع', 'Cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateOrderStatus(order, OrderStatus.rejected);
                          },
                          child: Text(AppStrings.t('رفض', 'Reject')),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(AppStrings.t('رفض', 'Reject')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  _updateOrderStatus(order, OrderStatus.accepted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.t('تم قبول الطلب', 'Order accepted'),
                      ),
                    ),
                  );
                },
                child: Text(AppStrings.t('قبول', 'Accept')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInProgressTab() {
    final inProgressOrders = _orders
        .where(
          (o) =>
              o.status == OrderStatus.accepted ||
              o.status == OrderStatus.inProgress,
        )
        .toList();
    if (inProgressOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('لا توجد طلبات قيد التنفيذ', 'No orders in progress'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: inProgressOrders.length,
      itemBuilder: (context, index) {
        final order = inProgressOrders[index];
        return _OrderCard(
          order: order,
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status == OrderStatus.accepted)
                FilledButton(
                  onPressed: () =>
                      _updateOrderStatus(order, OrderStatus.inProgress),
                  child: Text(AppStrings.t('بدء التنفيذ', 'Start work')),
                )
              else if (order.status == OrderStatus.inProgress) ...[
                OutlinedButton.icon(
                  onPressed: () => _uploadWorkPhoto(order),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(AppStrings.t('صور العمل', 'Work photos')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () =>
                      _updateOrderStatus(order, OrderStatus.completed),
                  child: Text(AppStrings.t('إنهاء الطلب', 'Finish order')),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final completedOrders = _orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    if (completedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.done_all, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppStrings.t('لا توجد طلبات مكتملة', 'No completed orders'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedOrders.length,
      itemBuilder: (context, index) {
        final order = completedOrders[index];
        return _OrderCard(order: order, actions: const SizedBox.shrink());
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Widget actions;

  const _OrderCard({required this.order, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        order.serviceName,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today,
              text: '${order.date} - ${order.time}',
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.location_on, text: order.location),
            if (actions is! SizedBox) ...[const SizedBox(height: 16), actions],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = status.getColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
