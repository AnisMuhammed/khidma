import 'package:flutter/material.dart';

import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/permission_service.dart';
import '../../models/provider_model.dart';

class OrderDetailsView extends StatefulWidget {
  const OrderDetailsView({super.key});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController(text: 'صنعاء - حدة');
  bool _isLocating = false;

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      final granted = await PermissionService.requestLocationPermission(
        context,
      );
      if (!mounted) return;
      if (granted) {
        setState(() {
          _locationController.text = AppStrings.t(
            'موقعي الحالي (تم التحديد عبر الـ GPS)',
            'My current location (detected via GPS)',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'تم تحديد موقعك الحالي بنجاح عبر الـ GPS ✓',
                'Your current location was detected successfully via GPS ✓',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'لم يتم السماح بالوصول للموقع، يمكنك إدخال العنوان يدوياً',
                'Location access was not granted. You can enter the address manually',
              ),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final previousArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> combinedArgs = {
      'description': _descriptionController.text.trim(),
      'notes': _notesController.text.trim(),
      'location': _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : 'صنعاء - حدة',
    };

    if (previousArgs is Map<String, dynamic>) {
      combinedArgs.addAll(previousArgs);
      // Keep user-entered details
      combinedArgs['description'] = _descriptionController.text.trim();
      combinedArgs['notes'] = _notesController.text.trim();
      combinedArgs['location'] = _locationController.text.trim();
    }

    Navigator.pushNamed(
      context,
      AppRoutes.orderConfirmation,
      arguments: combinedArgs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final args = ModalRoute.of(context)?.settings.arguments;
    String serviceName = AppStrings.t('خدمة منزلية', 'Home service');
    String providerName = AppStrings.t(
      'مزود خدمة معتمد',
      'Certified service provider',
    );
    String providerDetails = AppStrings.t(
      'مزود مسجل في المنصة',
      'Provider registered on the platform',
    );
    String date = AppStrings.t('اليوم المختار', 'Selected day');
    String time = AppStrings.t('الوقت المختار', 'Selected time');

    if (args is Map<String, dynamic>) {
      serviceName =
          args['serviceName']?.toString() ??
          args['title']?.toString() ??
          serviceName;
      providerName = args['providerName']?.toString() ?? providerName;
      date = args['date']?.toString() ?? date;
      time = args['time']?.toString() ?? time;
      if (args['provider'] != null && args['provider'] is ProviderModel) {
        final p = args['provider'] as ProviderModel;
        providerName = p.name;
        serviceName = p.serviceCategory;
        providerDetails = AppStrings.t(
          '${p.profession} • خبرة ${p.experienceYears} سنوات',
          '${p.profession} • ${p.experienceYears} years of experience',
        );
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('تفاصيل الطلب', 'Order Details')),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الخدمة
                _sectionCard(
                  context,
                  icon: Icons.home_repair_service_rounded,
                  title: AppStrings.t('الخدمة المطلوبة', 'Requested service'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppStrings.t(
                          'طلب صيانة وتنفيذ: $serviceName',
                          'Maintenance and service request: $serviceName',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // المزود
                _sectionCard(
                  context,
                  icon: Icons.person_rounded,
                  title: AppStrings.t('مزود الخدمة', 'Service provider'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(Icons.person, color: colors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              providerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(providerDetails),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // الموعد
                _sectionCard(
                  context,
                  icon: Icons.calendar_month_rounded,
                  title: AppStrings.t('الموعد', 'Appointment'),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          title: AppStrings.t('اليوم', 'Day'),
                          value: date,
                        ),
                      ),
                      Expanded(
                        child: _InfoItem(
                          title: AppStrings.t('الوقت', 'Time'),
                          value: time,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // وصف المشكلة
                Text(
                  AppStrings.t('وصف المشكلة', 'Problem description'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  textAlign: AppLanguageManager.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  decoration: InputDecoration(
                    hintText: AppStrings.t(
                      'اشرح المشكلة التي تريد من المزود حلها...',
                      'Describe the problem you need the provider to solve...',
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 65),
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.t(
                        'يرجى وصف المشكلة',
                        'Please describe the problem',
                      );
                    }

                    if (value.trim().length < 10) {
                      return AppStrings.t(
                        'اكتب وصفًا أوضح للمشكلة',
                        'Write a clearer description of the problem',
                      );
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // الملاحظات
                Text(
                  AppStrings.t('ملاحظات إضافية', 'Additional notes'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textAlign: AppLanguageManager.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  decoration: InputDecoration(
                    hintText: AppStrings.t(
                      'أي ملاحظات تريد إضافتها للمزود...',
                      'Any notes you want to add for the provider...',
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 45),
                      child: Icon(Icons.notes_rounded),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // عنوان وموقع تنفيذ الخدمة (مع إذن الموقع وتحديد GPS)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.t(
                        'عنوان وموقع تنفيذ الخدمة',
                        'Service address and location',
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLocating ? null : _detectLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(
                        AppStrings.t('تحديد موقعي الآن', 'Locate me now'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  textAlign: AppLanguageManager.isArabic
                      ? TextAlign.right
                      : TextAlign.left,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.t(
                        'يرجى إدخال عنوان أو مكان تنفيذ الخدمة',
                        'Please enter the service address or location',
                      );
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.t(
                      'مثلاً: صنعاء - حدة - شارع بيروت',
                      'Example: Sanaa - Hadda - Beirut Street',
                    ),
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    suffixIcon: IconButton(
                      tooltip: AppStrings.t(
                        'تحديد موقعي عبر الـ GPS',
                        'Locate me via GPS',
                      ),
                      icon: const Icon(Icons.gps_fixed_rounded),
                      onPressed: _isLocating ? null : _detectLocation,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                const SizedBox(height: 25),

                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _continue,
                    child: Text(
                      AppStrings.t(
                        'متابعة وتأكيد الطلب',
                        'Continue and confirm order',
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const _InfoItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
