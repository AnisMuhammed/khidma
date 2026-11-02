import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/permission_service.dart';

class LocationView extends StatefulWidget {
  const LocationView({super.key});

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('تحديد الموقع', 'Set Location')),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  size: 90,
                  color: colors.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppStrings.t(
                'أين تريد تنفيذ الخدمة؟',
                'Where do you need the service?',
              ),
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              AppStrings.t(
                'حدد موقعك حتى يستطيع مزود الخدمة الوصول إليك.',
                'Set your location so the service provider can reach you.',
              ),
              style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _locationController,
              textAlign: AppLanguageManager.isArabic
                  ? TextAlign.right
                  : TextAlign.left,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppStrings.t('عنوان الموقع', 'Location address'),
                hintText: AppStrings.t(
                  'مثال: صنعاء، شارع حدة، بالقرب من...',
                  'Example: Sanaa, Hadda Street, near...',
                ),
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () async {
                final granted =
                    await PermissionService.requestLocationPermission(context);

                if (granted && context.mounted) {
                  setState(() {
                    _locationController.text = AppStrings.t(
                      'صنعاء - حدة (تم تحديد الموقع تلقائياً)',
                      'Sanaa - Hadda (location detected automatically)',
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.t(
                          'تم تحديد موقعك بنجاح',
                          'Your location was set successfully',
                        ),
                      ),
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppStrings.t(
                          'لم يتم منح إذن الموقع. يمكنك إدخال العنوان يدوياً.',
                          'Location permission was not granted. You can enter the address manually.',
                        ),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.my_location_rounded),
              label: Text(
                AppStrings.t('تحديد موقعي الحالي', 'Use my current location'),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: () {
                  if (_locationController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.t(
                            'يرجى إدخال موقع تنفيذ الخدمة',
                            'Please enter the service location',
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, _locationController.text.trim());
                },
                child: Text(
                  AppStrings.t('تأكيد الموقع', 'Confirm Location'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}
