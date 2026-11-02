import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../data/user_session.dart';
import '../../viewmodels/order_viewmodel.dart';

class OrderConfirmationView extends StatefulWidget {
  const OrderConfirmationView({super.key});

  @override
  State<OrderConfirmationView> createState() => _OrderConfirmationViewState();
}

class _OrderConfirmationViewState extends State<OrderConfirmationView> {
  String _location = '';
  bool _initialized = false;

  String _description = '';
  String _notes = '';

  String _serviceName = AppStrings.t('خدمة منزلية', 'Home service');
  String _providerName = AppStrings.t(
    'مزود خدمة معتمد',
    'Certified service provider',
  );

  // معرف مزود الخدمة
  String _providerId = '';

  String _date = AppStrings.t('اليوم المختار', 'Selected day');
  String _time = AppStrings.t('الوقت المختار', 'Selected time');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        _serviceName = args['serviceName']?.toString() ?? _serviceName;

        _providerName = args['providerName']?.toString() ?? _providerName;

        if (args['provider'] != null) {
          try {
            final p = args['provider'];
            _providerId = p.id.toString();
            _providerName = p.name.toString();
            if (p.serviceCategory != null &&
                p.serviceCategory.toString().isNotEmpty) {
              _serviceName = p.serviceCategory.toString();
            }
          } catch (_) {}
        }

        if (args['providerId'] != null &&
            args['providerId'].toString().isNotEmpty) {
          _providerId = args['providerId'].toString();
        }

        _date = args['date']?.toString() ?? _date;

        _time = args['time']?.toString() ?? _time;

        _location = args['location']?.toString() ?? _location;

        _description = args['description']?.toString() ?? _description;

        _notes = args['notes']?.toString() ?? _notes;
      }

      _initialized = true;
    }
  }

  Future<void> _sendOrder() async {
    final clientName = UserSession.currentUser.name.isNotEmpty
        ? UserSession.currentUser.name
        : AppStrings.t('العميل', 'Client');

    final clientId = UserSession.currentUser.id.isNotEmpty
        ? UserSession.currentUser.id
        : 'client_${DateTime.now().millisecondsSinceEpoch}';

    final providerId = _providerId.isNotEmpty
        ? _providerId
        : 'prov_${_providerName.hashCode.abs()}';

    try {
      await OrderViewModel().createOrder(
        clientId: clientId,
        providerId: providerId,

        clientName: clientName,
        providerName: _providerName,

        serviceName: _serviceName,

        description: _description.isNotEmpty
            ? _description
            : AppStrings.t('طلب خدمة جديد', 'New service request'),

        location: _location,
        date: _date,
        time: _time,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orderSuccess,
        arguments: AppStrings.t(
          'حسب الاتفاق مع مزود الخدمة',
          'By agreement with the service provider',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(
              'حدث خطأ أثناء إرسال الطلب: $e',
              'An error occurred while sending the order: $e',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('تأكيد الطلب', 'Confirm Order')),
          centerTitle: true,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // العنوان
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 40,
                      color: colors.primary,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            AppStrings.t('مراجعة الطلب', 'Review Order'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            AppStrings.t(
                              'راجع بيانات طلبك قبل التأكيد والإرسال',
                              'Review your order details before confirming and sending',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _InfoCard(
                icon: Icons.home_repair_service_rounded,
                title: AppStrings.t('الخدمة', 'Service'),
                value: _serviceName,
              ),

              _InfoCard(
                icon: Icons.person_rounded,
                title: AppStrings.t('مزود الخدمة', 'Service provider'),
                value: _providerName,
              ),

              _InfoCard(
                icon: Icons.star_rounded,
                title: AppStrings.t('التقييم', 'Rating'),
                value: '4.9 / 5',
              ),

              _InfoCard(
                icon: Icons.calendar_month_rounded,
                title: AppStrings.t('الموعد', 'Appointment'),
                value: '$_date - $_time',
              ),

              _InfoCard(
                icon: Icons.description_rounded,
                title: AppStrings.t('وصف المشكلة', 'Problem description'),
                value: _description.isNotEmpty
                    ? _description
                    : AppStrings.t('لا يوجد وصف', 'No description'),
              ),

              _InfoCard(
                icon: Icons.notes_rounded,
                title: AppStrings.t('الملاحظات', 'Notes'),
                value: _notes.isNotEmpty
                    ? _notes
                    : AppStrings.t('لا توجد ملاحظات', 'No notes'),
              ),

              const SizedBox(height: 5),

              // الموقع
              Container(
                padding: const EdgeInsets.all(16),

                margin: const EdgeInsets.only(bottom: 14),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineVariant),
                ),

                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: colors.primary),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            AppStrings.t(
                              'موقع تنفيذ الخدمة',
                              'Service location',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            _location.isNotEmpty
                                ? _location
                                : AppStrings.t(
                                    'لم يتم تحديد الموقع',
                                    'Location not set',
                                  ),

                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),

                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          AppRoutes.location,
                        );

                        if (result is String && result.isNotEmpty) {
                          setState(() {
                            _location = result;
                          });
                        }
                      },

                      icon: const Icon(
                        Icons.edit_location_alt_rounded,
                        size: 18,
                      ),

                      label: Text(AppStrings.t('تغيير', 'Change')),
                    ),
                  ],
                ),
              ),

              // السعر
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  children: [
                    Icon(Icons.handshake_rounded, color: colors.primary),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        AppStrings.t('تكلفة الخدمة', 'Service cost'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    Text(
                      AppStrings.t('حسب الاتفاق المباشر', 'By direct agreement'),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 56,

                child: FilledButton.icon(
                  onPressed: _sendOrder,

                  icon: const Icon(Icons.send_rounded),

                  label: Text(
                    AppStrings.t(
                      'تأكيد وإرسال الطلب',
                      'Confirm and send order',
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),

      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: colors.outlineVariant),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, color: colors.primary, size: 22),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,

                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
