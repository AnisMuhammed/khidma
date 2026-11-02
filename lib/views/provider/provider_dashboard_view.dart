import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/orders_data.dart';
import '../../data/user_session.dart';
import '../../models/order_model.dart';
import '../../models/provider_model.dart';
import '../../services/auth_service.dart';

class ProviderDashboardView extends StatelessWidget {
  const ProviderDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pendingCount = providerOrdersData
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final inProgressCount = providerOrdersData
        .where(
          (o) =>
              o.status == OrderStatus.accepted ||
              o.status == OrderStatus.inProgress,
        )
        .length;
    final completedCount = providerOrdersData
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final ratingValue = UserSession.currentProvider.rating.toStringAsFixed(1);

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('لوحة مزود الخدمة', 'Provider Dashboard')),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: AppStrings.t('تسجيل الخروج', 'Log out'),
              onPressed: () async {
                await AuthService.signOut();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة المزود
            ValueListenableBuilder<ProviderModel>(
              valueListenable: UserSession.providerNotifier,
              builder: (context, provider, _) {
                final imageProvider = AppImageHelper.getImageProvider(
                  provider.profileImagePath,
                );

                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.providerEditProfile);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? const Icon(Icons.person_rounded, size: 38)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.t(
                                  'مرحباً، ${provider.name}',
                                  'Welcome, ${provider.name}',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                provider.profession,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // حالة التوفر
            ValueListenableBuilder<ProviderModel>(
              valueListenable: UserSession.providerNotifier,
              builder: (context, prov, _) {
                final isAvail = prov.isAvailable;
                return Card(
                  child: SwitchListTile(
                    value: isAvail,
                    activeThumbColor: colors.primary,
                    onChanged: (value) {
                      UserSession.toggleProviderAvailability(value);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? AppStrings.t(
                                    'أنت الآن متاح لاستقبال الطلبات ✓',
                                    'You are now available to receive orders ✓',
                                  )
                                : AppStrings.t(
                                    'تم تغيير حالتك إلى غير متاح حالياً ✕',
                                    'Your status was changed to unavailable ✕',
                                  ),
                          ),
                          backgroundColor: value
                              ? const Color(0xFF0F766E)
                              : Colors.orange,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    title: Text(
                      isAvail
                          ? AppStrings.t(
                              'متاح لاستقبال الطلبات',
                              'Available for orders',
                            )
                          : AppStrings.t('غير متاح حالياً', 'Currently unavailable'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isAvail
                          ? AppStrings.t(
                              'يمكن للعملاء إرسال طلبات جديدة إليك',
                              'Clients can send you new orders',
                            )
                          : AppStrings.t(
                              'لن تظهر كمزود متاح للعمل حتى تعيد التفعيل',
                              'You will not appear as an available provider until you re-enable this',
                            ),
                    ),
                    secondary: Icon(
                      Icons.circle,
                      color: isAvail ? Colors.green : Colors.grey,
                      size: 14,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              AppStrings.t('ملخص النشاط', 'Activity Summary'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions_rounded,
                    title: AppStrings.t('طلبات جديدة', 'New orders'),
                    value: pendingCount.toString(),
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.work_history_rounded,
                    title: AppStrings.t('قيد التنفيذ', 'In progress'),
                    value: inProgressCount.toString(),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    title: AppStrings.t('مكتملة', 'Completed'),
                    value: completedCount.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_rounded,
                    title: AppStrings.t('التقييم', 'Rating'),
                    value: ratingValue,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Text(
              AppStrings.t('إدارة الخدمة', 'Service Management'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            _DashboardTile(
              icon: Icons.receipt_long_rounded,
              title: AppStrings.t('طلبات العملاء', 'Client orders'),
              subtitle: AppStrings.t(
                'عرض الطلبات الجديدة والحالية',
                'View new and current orders',
              ),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.providerOrders);
              },
            ),
            _DashboardTile(
              icon: Icons.person_rounded,
              title: AppStrings.t('ملف مزود الخدمة', 'Provider profile'),
              subtitle: AppStrings.t(
                'الخبرة والشهادات والأعمال السابقة',
                'Experience, certificates and previous work',
              ),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.providerEditProfile);
              },
            ),

            _DashboardTile(
              icon: Icons.calendar_month_rounded,
              title: AppStrings.t('أوقات التوفر', 'Availability times'),
              subtitle: AppStrings.t(
                'حدد الأيام والأوقات التي تعمل فيها',
                'Set the days and times you work',
              ),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.providerSchedule);
              },
            ),

            _DashboardTile(
              icon: Icons.photo_library_rounded,
              title: AppStrings.t('أعمالي السابقة', 'My previous work'),
              subtitle: AppStrings.t(
                'أضف صور الأعمال قبل وبعد',
                'Add before and after photos of your work',
              ),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.providerPreviousWork);
              },
            ),

            _DashboardTile(
              icon: Icons.account_balance_wallet_rounded,
              title: AppStrings.t('الأرباح', 'Earnings'),
              subtitle: AppStrings.t(
                'متابعة المبالغ والطلبات المكتملة',
                'Track amounts and completed orders',
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.t('ملخص الأرباح', 'Earnings Summary'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                            ),
                            title: Text(
                              AppStrings.t(
                                'الطلبات المكتملة',
                                'Completed orders',
                              ),
                            ),
                            trailing: const Text(
                              '38',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.payments_rounded,
                              color: Colors.blue,
                            ),
                            title: Text(
                              AppStrings.t('طريقة الدفع', 'Payment method'),
                            ),
                            trailing: Text(
                              AppStrings.t('اتفاق مباشر', 'Direct agreement'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.orange,
                            ),
                            title: Text(
                              AppStrings.t(
                                'طلبات هذا الشهر',
                                'Orders this month',
                              ),
                            ),
                            trailing: const Text(
                              '5',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                );
              },
            ),
          ],
        ),
      );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: colors.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: colors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Icon(
          AppLanguageManager.currentDirection == TextDirection.rtl
              ? Icons.arrow_back_ios_new_rounded
              : Icons.arrow_forward_ios_rounded,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
