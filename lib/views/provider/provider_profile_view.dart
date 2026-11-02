import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/permission_service.dart';
import '../../core/utils/app_image_helper.dart';
import '../../core/utils/category_helper.dart';
import '../../data/user_session.dart';
import '../../models/provider_model.dart';

class ProviderProfileView extends StatefulWidget {
  const ProviderProfileView({super.key});

  @override
  State<ProviderProfileView> createState() => _ProviderProfileViewState();
}

class _ProviderProfileViewState extends State<ProviderProfileView> {
  late ProviderModel _provider;
  late TextEditingController _nameController;
  late TextEditingController _professionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _yearsController;
  String? _profileImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _provider = UserSession.currentProvider;
    _nameController = TextEditingController(text: _provider.name);
    _professionController = TextEditingController(text: _provider.profession);
    _phoneController = TextEditingController(text: _provider.phone);
    _emailController = TextEditingController(text: _provider.email);
    _bioController = TextEditingController(text: _provider.bio);
    _yearsController = TextEditingController(
      text: _provider.experienceYears.toString(),
    );
    _profileImagePath = _provider.profileImagePath;
  }

  Future<void> _pickProfileImage() async {
    final picked = await PermissionService.pickImage(context);
    if (picked != null && mounted) {
      setState(() {
        _profileImagePath = picked.path;
        _provider.profileImagePath = picked.path;
      });
      await UserSession.saveProviderFullProfile(_provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'تم تحديث الصورة الشخصية',
                'Profile photo updated',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickCertificate() async {
    final image = await PermissionService.pickImage(context);

    if (image != null && mounted) {
      final certController = TextEditingController(
        text: AppStrings.t(
          'شهادة كفاءة مهنية جديدة',
          'New professional certificate',
        ),
      );
      final certTitle = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.t('اسم الشهادة', 'Certificate name')),
          content: TextField(
            controller: certController,
            decoration: InputDecoration(
              labelText: AppStrings.t(
                'اسم الشهادة أو الدورة',
                'Certificate or course name',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.t('إلغاء', 'Cancel')),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, certController.text.trim()),
              child: Text(AppStrings.t('إضافة', 'Add')),
            ),
          ],
        ),
      );

      if (certTitle != null && certTitle.isNotEmpty && mounted) {
        setState(() {
          _provider.certificates.add(certTitle);
        });
        await UserSession.saveProviderFullProfile(_provider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(
                  'تم إضافة الشهادة بنجاح',
                  'Certificate added successfully',
                ),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _verifyIdentity() async {
    final image = await PermissionService.pickImage(context);

    if (image != null && mounted) {
      setState(() {
        _provider.isVerified = true;
      });
      await UserSession.saveProviderFullProfile(_provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'تم توثيق الهوية بنجاح ✓',
                'Identity verified successfully ✓',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final profession = _professionController.text.trim();
    final bio = _bioController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final years =
        int.tryParse(_yearsController.text.trim()) ?? _provider.experienceYears;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(
              'يرجى إدخال اسم مزود الخدمة',
              'Please enter the provider name',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      _provider.name = name;
      _provider.profession = profession.isNotEmpty
          ? profession
          : 'مزود خدمة محترف';
      _provider.serviceCategory = CategoryHelper.normalizeCategory(profession);
      _provider.bio = bio;
      _provider.experienceYears = years;
      _provider.phone = phone;
      if (email.isNotEmpty) {
        _provider.email = email;
      }
      if (_profileImagePath != null) {
        _provider.profileImagePath = _profileImagePath;
      }

      await UserSession.saveProviderFullProfile(_provider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'تم حفظ وتحديث بيانات الملف المهني بنجاح ✓',
                'Professional profile data was saved and updated successfully ✓',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.t(
                'حدث خطأ أثناء الحفظ: $e',
                'An error occurred while saving: $e',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _section(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageProvider = AppImageHelper.getImageProvider(_profileImagePath);

    return Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('ملفي المهني', 'My Professional Profile')),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Icon(Icons.person, size: 50, color: colors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.primary,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(
              AppStrings.t('الاسم الكامل', 'Full name'),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _section(
              AppStrings.t('المهنة والتخصص', 'Profession and specialty'),
              TextFormField(
                controller: _professionController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _section(
              AppStrings.t('رقم الهاتف والواتساب', 'Phone and WhatsApp number'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _section(
              AppStrings.t('البريد الإلكتروني', 'Email address'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _section(
              AppStrings.t('نبذة شخصية عن خبرتك', 'A short bio about your experience'),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: AppStrings.t(
                    'اكتب نبذة عن مهاراتك والخدمات التي تقدمها...',
                    'Write about your skills and the services you offer...',
                  ),
                ),
              ),
            ),
            _section(
              AppStrings.t('سنوات الخبرة', 'Years of experience'),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _yearsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(AppStrings.t('سنوات في المجال', 'years in the field')),
                ],
              ),
            ),
            _section(
              AppStrings.t(
                'الشهادات والاعتمادات',
                'Certificates and accreditations',
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _provider.certificates
                        .map(
                          (cert) => Chip(
                            label: Text(cert),
                            backgroundColor: colors.surfaceContainerHighest,
                            avatar: const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickCertificate,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(
                      AppStrings.t(
                        'إضافة شهادة من المعرض أو الكاميرا',
                        'Add a certificate from gallery or camera',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              AppStrings.t('حالة التوثيق', 'Verification status'),
              Row(
                children: [
                  Icon(
                    _provider.isVerified
                        ? Icons.verified_rounded
                        : Icons.pending_rounded,
                    color: _provider.isVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _provider.isVerified
                        ? AppStrings.t(
                            'حساب موثق بالهوية',
                            'Identity-verified account',
                          )
                        : AppStrings.t('غير موثق بعد', 'Not verified yet'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _verifyIdentity,
                    icon: const Icon(Icons.badge_rounded, size: 18),
                    label: Text(
                      _provider.isVerified
                          ? AppStrings.t('تحديث التوثيق', 'Update verification')
                          : AppStrings.t('توثيق الهوية', 'Verify identity'),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              AppStrings.t('الأعمال السابقة', 'Previous work'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t(
                      '${_provider.previousWorks.length} أعمال مسجلة',
                      '${_provider.previousWorks.length} registered works',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.providerPreviousWork,
                      ).then((_) {
                        if (mounted) {
                          setState(() {
                            _provider = UserSession.currentProvider;
                          });
                        }
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                    label: Text(
                      AppStrings.t(
                        'إدارة الأعمال السابقة',
                        'Manage previous work',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _section(
              AppStrings.t('أوقات التوفر', 'Availability times'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t(
                      'السبت - الخميس (08:00 ص - 06:00 م)',
                      'Saturday - Thursday (08:00 AM - 06:00 PM)',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.providerSchedule);
                    },
                    child: Text(AppStrings.t('تعديل', 'Edit')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      AppStrings.t('حفظ التعديلات', 'Save Changes'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      );
  }
}
