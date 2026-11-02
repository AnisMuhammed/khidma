import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/permission_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/user_session.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sqlite_service.dart';

class ProviderSetupView extends StatefulWidget {
  const ProviderSetupView({super.key});

  @override
  State<ProviderSetupView> createState() => _ProviderSetupViewState();
}

class _ProviderSetupViewState extends State<ProviderSetupView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController professionController = TextEditingController();

  final TextEditingController experienceController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController whatsappController = TextEditingController();

  String? selectedService;
  File? _previousWorkImage;
  File? _certificateImage;
  File? _idImage;

  // قائمة المهن قيم بيانات لا تُترجم: `selectedService` يُخزَّن كما هو في
  // `profession` و`serviceCategory` ويُطابق عبر `CategoryHelper`، فترجمته تكسر
  // المطابقة. تُترجم واجهة الشاشة فقط.
  final List<String> services = [
    'سباك',
    'كهربائي',
    'دهان',
    'منظف',
    'نجار',
    'ديكور',
    'فني تكييف',
    'صيانة أجهزة',
    'حداد',
    'بلاط',
    'خدمات أخرى',
  ];

  @override
  void dispose() {
    professionController.dispose();
    experienceController.dispose();
    descriptionController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picked = await PermissionService.pickImage(context);
    if (picked == null || !mounted) return;

    setState(() {
      switch (type) {
        case 'work':
          _previousWorkImage = File(picked.path);
          break;
        case 'certificate':
          _certificateImage = File(picked.path);
          break;
        case 'id':
          _idImage = File(picked.path);
          break;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t('تم اختيار الصورة بنجاح', 'Image selected successfully'),
          ),
        ),
      );
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final chosenService = selectedService ?? 'خدمات عامة';
    final years = int.tryParse(experienceController.text.trim()) ?? 1;
    final bio = descriptionController.text.trim();
    final phone = whatsappController.text.trim();

    // الحصول على UID الحقيقي من Firebase Auth أو الجلسة
    final firebaseUid =
        FirebaseAuth.instance.currentUser?.uid ?? UserSession.currentProvider.id;

    final provider = UserSession.currentProvider;
    // تعيين ID الحقيقي من Firebase Auth
    if (firebaseUid.isNotEmpty && firebaseUid != 'provider_guest') {
      provider.id = firebaseUid;
    }
    provider.profession = chosenService;
    provider.serviceCategory = chosenService;
    provider.bio = bio.isNotEmpty
        ? bio
        : 'مزود خدمة محترف في مجال $chosenService';
    provider.experienceYears = years;
    provider.phone = phone.isNotEmpty ? phone : provider.phone;
    if (_idImage != null) {
      provider.profileImagePath = _idImage!.path;
    }
    if (_previousWorkImage != null) {
      provider.previousWorks = [
        PreviousWork(
          title: 'عمل سابق في $chosenService',
          description: bio.isNotEmpty
              ? bio
              : 'تنفيذ أعمال $chosenService بجودة عالية',
          beforeImagePath: _previousWorkImage!.path,
          afterImagePath: _previousWorkImage!.path,
        ),
      ];
    }
    if (_certificateImage != null) {
      provider.certificates = ['شهادة خبرة معتمدة'];
    }

    UserSession.updateProviderProfile(
      name: provider.name,
      profession: provider.profession,
      bio: provider.bio,
      experienceYears: provider.experienceYears,
      phone: provider.phone,
      profileImagePath: provider.profileImagePath,
    );

    // حفظ في Firestore و SQLite بالـ UID الصحيح
    try {
      await FirestoreService.saveProvider(provider);
      await SqliteService.insertOrUpdateProvider(provider);
    } catch (e) {
      debugPrint('Error saving provider setup: $e');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.t(
            'تم تجهيز ملفك المهني بنجاح! مرحباً بك في لوحة التحكم',
            'Your professional profile is ready! Welcome to your dashboard',
          ),
        ),
        backgroundColor: const Color(0xFF0F766E),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.providerDashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.t('إعداد ملف مزود الخدمة', 'Provider Profile Setup'),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.engineering_outlined,
                        size: 55,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.t(
                          'أنشئ ملفك المهني',
                          'Create your professional profile',
                        ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.t(
                          'أدخل معلوماتك حتى يتمكن العملاء من معرفة خبرتك وخدماتك.',
                          'Enter your details so clients can learn about your experience and services.',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Service
                DropdownButtonFormField<String>(
                  initialValue: selectedService,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('نوع الخدمة', 'Service type'),
                    prefixIcon: const Icon(Icons.build_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: services.map((service) {
                    return DropdownMenuItem(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedService = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.t(
                        'اختر نوع الخدمة',
                        'Choose a service type',
                      );
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Experience
                TextFormField(
                  controller: experienceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('سنوات الخبرة', 'Years of experience'),
                    hintText: AppStrings.t('مثال: 5', 'Example: 5'),
                    prefixIcon: const Icon(Icons.workspace_premium_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.t(
                        'أدخل سنوات الخبرة',
                        'Enter the years of experience',
                      );
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Profession
                TextFormField(
                  controller: professionController,
                  decoration: InputDecoration(
                    labelText: AppStrings.t(
                      'المهنة / التخصص',
                      'Profession / Specialty',
                    ),
                    hintText: AppStrings.t(
                      'مثال: فني كهرباء منازل',
                      'Example: Home electrical technician',
                    ),
                    prefixIcon: const Icon(Icons.work_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.t(
                        'أدخل تخصصك',
                        'Enter your specialty',
                      );
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // WhatsApp
                TextFormField(
                  controller: whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('رقم واتساب', 'WhatsApp number'),
                    hintText: AppStrings.t('مثال: 777123456', 'Example: 777123456'),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.t(
                        'أدخل رقم واتساب',
                        'Enter a WhatsApp number',
                      );
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: AppStrings.t('نبذة عن خدماتك', 'About your services'),
                    hintText: AppStrings.t(
                      'اكتب نبذة مختصرة عن خبرتك والخدمات التي تقدمها...',
                      'Write a short summary of your experience and the services you offer...',
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 75),
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.t(
                        'اكتب نبذة عن خدماتك',
                        'Write a summary of your services',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // Previous work
                _UploadCard(
                  icon: Icons.photo_library_outlined,
                  title: AppStrings.t('الأعمال السابقة', 'Previous work'),
                  subtitle: AppStrings.t(
                    'أضف صورًا من أعمالك السابقة',
                    'Add photos of your previous work',
                  ),
                  onTap: () => _pickImage('work'),
                ),
                if (_previousWorkImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: AppImageHelper.buildImage(
                      path: _previousWorkImage!.path,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      cacheHeight:
                          (120 * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                  ),

                const SizedBox(height: 12),

                // Certificates
                _UploadCard(
                  icon: Icons.workspace_premium_outlined,
                  title: AppStrings.t(
                    'الشهادات والخبرات',
                    'Certificates and experience',
                  ),
                  subtitle: AppStrings.t(
                    'أضف صور الشهادات إن وجدت',
                    'Add photos of your certificates, if any',
                  ),
                  onTap: () => _pickImage('certificate'),
                ),
                if (_certificateImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: AppImageHelper.buildImage(
                      path: _certificateImage!.path,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      cacheHeight:
                          (120 * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                  ),

                const SizedBox(height: 12),

                // ID verification
                _UploadCard(
                  icon: Icons.verified_user_outlined,
                  title: AppStrings.t('إثبات الهوية', 'Identity proof'),
                  subtitle: AppStrings.t(
                    'أضف صورة البطاقة للتحقق من حسابك',
                    'Add a photo of your ID to verify your account',
                  ),
                  onTap: () => _pickImage('id'),
                ),
                if (_idImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: AppImageHelper.buildImage(
                      path: _idImage!.path,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      cacheHeight:
                          (120 * MediaQuery.devicePixelRatioOf(context))
                              .round(),
                    ),
                  ),

                const SizedBox(height: 10),

                Text(
                  AppStrings.t(
                    'ملاحظة: صورة الهوية تستخدم للتحقق من الحساب ولن يتم عرضها للعملاء.',
                    'Note: the ID photo is used to verify your account and will not be shown to clients.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _continue,
                    child: Text(
                      AppStrings.t('متابعة', 'Continue'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
  }
}

class _UploadCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UploadCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              AppLanguageManager.currentDirection == TextDirection.rtl
                  ? Icons.arrow_back_ios_new
                  : Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
