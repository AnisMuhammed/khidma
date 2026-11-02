import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/permission_service.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/user_session.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    final client = UserSession.currentClient;
    nameController = TextEditingController(text: client.name);
    phoneController = TextEditingController(text: client.phone);
    emailController = TextEditingController(text: client.email);
    _profileImagePath = client.profileImagePath;
  }

  Future<void> _pickImage() async {
    final picked = await PermissionService.pickImage(context);
    if (picked != null && mounted) {
      setState(() {
        _profileImagePath = picked.path;
      });
      UserSession.updateClientProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        profileImagePath: picked.path,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(
              'تم تحديد وتحديث الصورة بنجاح',
              'Photo selected and updated successfully',
            ),
          ),
        ),
      );
    }
  }

  void _saveChanges() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t('يرجى إدخال الاسم', 'Please enter a name')),
        ),
      );
      return;
    }

    UserSession.updateClientProfile(
      name: name,
      email: email,
      phone: phone,
      profileImagePath: _profileImagePath,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.t(
            'تم حفظ التعديلات بنجاح',
            'Changes saved successfully',
          ),
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageProvider = AppImageHelper.getImageProvider(_profileImagePath);

    return Scaffold(
      appBar: AppBar(
          title: Text(AppStrings.t('تعديل الملف الشخصي', 'Edit Profile')),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person_rounded, size: 65)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: CircleAvatar(
                      backgroundColor: colors.primary,
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppStrings.t('الاسم الكامل', 'Full name'),
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppStrings.t('رقم الهاتف', 'Phone number'),
                prefixIcon: const Icon(Icons.phone_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppStrings.t('البريد الإلكتروني', 'Email address'),
                prefixIcon: const Icon(Icons.email_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: FilledButton(
                onPressed: _saveChanges,
                child: Text(
                  AppStrings.t('حفظ التعديلات', 'Save Changes'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}
