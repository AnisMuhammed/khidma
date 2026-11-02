import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../localization/app_language_manager.dart';
import '../localization/app_strings.dart';

class PermissionService {
  static final ImagePicker _picker = ImagePicker();

  /// التحقق مما إذا كانت المنصة لا تتطلب أذونات الهواتف (مثل الويندوز والمتصفح)
  static bool get _isDesktopOrWeb =>
      kIsWeb || (!Platform.isAndroid && !Platform.isIOS);

  /// التقاط صورة بتدفق موحد: اختيار المصدر -> فحص الأذونات -> التقاط الصورة
  static Future<XFile?> pickImage(
    BuildContext context, {
    ImageSource? directSource,
  }) async {
    final String? sourceString;
    if (directSource == null) {
      final selected = await showImageSourceSelector(context);
      if (selected == null || !context.mounted) return null;
      sourceString = selected.toString();
    } else {
      sourceString = directSource == ImageSource.camera ? 'camera' : 'gallery';
    }

    try {
      if (sourceString == 'camera') {
        final bool hasPermission = await requestCameraPermission(context);
        if (!hasPermission || !context.mounted) return null;
        return await _picker.pickImage(source: ImageSource.camera);
      } else {
        final bool hasPermission = await requestPhotosPermission(context);
        if (!hasPermission || !context.mounted) return null;
        return await _picker.pickImage(source: ImageSource.gallery);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// طلب إذن الوصول للموقع مع نافذة شرح
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // عرض نافذة الشرح والطلب للمستخدم أولاً مع زرّي (رفض / قبول)
    final shouldRequest = await _showPermissionDialog(
      context: context,
      icon: Icons.location_on_rounded,
      title: AppStrings.t('إذن الوصول إلى الموقع', 'Location access permission'),
      description: AppStrings.t(
        'يريد تطبيق خِدْمَة الوصول إلى موقعك لتحديد موقعك وتسهيل وصول مزود الخدمة إليك بدقة.',
        'The Khidma app would like to access your location so the service provider can reach you accurately.',
      ),
    );

    if (!shouldRequest) return false;

    // إذا كنا على منصة الويب أو الديسكتوب، فموافقة المستخدم في النافذة تكفي
    if (_isDesktopOrWeb) return true;

    // التحقق أولاً مما إذا كانت خدمة الموقع (GPS) مغلقة على الهاتف
    final isServiceEnabled = await Permission.location.serviceStatus.isEnabled;
    if (!isServiceEnabled && context.mounted) {
      final openSettings = await _showGpsDisabledDialog(context);
      if (openSettings) {
        await openAppSettings();
      }
    }

    // طلب إذن الموقع من نظام التشغيل
    final status = await Permission.location.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context);
      return false;
    }

    return false;
  }

  /// نافذة تنبيه إذا كانت خدمة الـ GPS مغلقة في الجهاز
  static Future<bool> _showGpsDisabledDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Directionality.maybeOf(context) ?? AppLanguageManager.currentDirection,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.t('خدمة الموقع (GPS) مغلقة', 'Location (GPS) is off'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.t(
              'خدمة تحديد الموقع (GPS) مغلقة في جهازك. يرجى تفعيل الموقع لنتمكن من تحديد عنوانك تلقائياً.',
              'Location services (GPS) are turned off on your device. Please enable location so we can detect your address automatically.',
            ),
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.t('إلغاء', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                AppStrings.t('فتح إعدادات الموقع', 'Open location settings'),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// طلب إذن الوصول للكاميرا مع نافذة شرح
  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (_isDesktopOrWeb) return true;
    return _requestPermission(
      context: context,
      permission: Permission.camera,
      icon: Icons.camera_alt_rounded,
      title: AppStrings.t('إذن الوصول للكاميرا', 'Camera access permission'),
      description: AppStrings.t(
        'يحتاج التطبيق إلى إذن الكاميرا لالتقاط صور أعمالك وتوثيق حسابك.',
        'The app needs camera access to take photos of your work and verify your account.',
      ),
    );
  }

  /// طلب إذن الوصول للصور والملفات مع نافذة شرح
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    if (_isDesktopOrWeb) return true;

    // التحقق أولاً إذا كان الإذن ممنوحاً بالفعل
    if (await Permission.photos.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    if (!context.mounted) return false;

    // عرض نافذة الشرح المسبقة
    final shouldRequest = await _showPermissionDialog(
      context: context,
      icon: Icons.photo_library_rounded,
      title: AppStrings.t(
        'إذن الوصول للصور والملفات',
        'Photos and files access permission',
      ),
      description: AppStrings.t(
        'يحتاج التطبيق إلى إذن الوصول للصور لاختيار الصور والملفات من جهازك.',
        'The app needs access to your photos in order to pick images and files from your device.',
      ),
    );

    if (!shouldRequest || !context.mounted) return false;

    // محاولة طلب إذن الصور لنظام Android 13+ و iOS
    PermissionStatus status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    // إذا لم يُمنح (مثل إصدارات أندرويد 12 وما قبلها) نطلب إذن التخزين
    status = await Permission.storage.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context);
      return false;
    }

    // في أندرويد الحديث ومحدد الصور الافتراضي للنظام لا يشترط إذن دائم لفتح الملفات
    return true;
  }

  /// نافذة منبثقة لاختيار مصدر الصورة (الكاميرا أو المعرض/الملفات)
  static Future<dynamic> showImageSourceSelector(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return Directionality(
          textDirection: Directionality.maybeOf(context) ?? AppLanguageManager.currentDirection,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.t('اختيار مصدر الصورة', 'Choose image source'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: colors.primary,
                    ),
                  ),
                  title: Text(
                    AppStrings.t('الكاميرا', 'Camera'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    AppStrings.t(
                      'التقاط صورة مباشرة باستخدام الكاميرا',
                      'Take a photo directly with the camera',
                    ),
                  ),
                  trailing: Icon(
                    AppLanguageManager.currentDirection == TextDirection.rtl
                        ? Icons.arrow_back_ios_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => Navigator.pop(ctx, 'camera'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  title: Text(
                    AppStrings.t('معرض الصور والملفات', 'Photo gallery and files'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    AppStrings.t(
                      'اختيار صورة من ملفات ومعرض الجهاز',
                      'Pick an image from your device files and gallery',
                    ),
                  ),
                  trailing: Icon(
                    AppLanguageManager.currentDirection == TextDirection.rtl
                        ? Icons.arrow_back_ios_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => Navigator.pop(ctx, 'gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// طلب إذن مع عرض نافذة شرح أولاً
  static Future<bool> _requestPermission({
    required BuildContext context,
    required Permission permission,
    required IconData icon,
    required String title,
    required String description,
  }) async {
    // التحقق إذا كان الإذن ممنوحاً مسبقاً
    final status = await permission.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;

    // عرض نافذة الشرح أولاً
    final shouldRequest = await _showPermissionDialog(
      context: context,
      icon: icon,
      title: title,
      description: description,
    );

    if (!shouldRequest) return false;

    // طلب الإذن من النظام
    final result = await permission.request();

    if (result.isGranted) return true;

    // إذا تم الرفض بشكل دائم
    if (result.isPermanentlyDenied && context.mounted) {
      await _showSettingsDialog(context);
    }

    return false;
  }

  /// نافذة منبثقة لشرح سبب طلب الإذن مع زر قبول وزر رفض
  static Future<bool> _showPermissionDialog({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) async {
    final colors = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: Directionality.maybeOf(context) ?? AppLanguageManager.currentDirection,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: colors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  height: 1.7,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppStrings.t('رفض', 'Deny'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppStrings.t('قبول', 'Allow'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  /// نافذة توجيه المستخدم لإعدادات التطبيق عند الرفض الدائم
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.maybeOf(context) ?? AppLanguageManager.currentDirection,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            AppStrings.t('الإذن مطلوب', 'Permission required'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppStrings.t(
              'تم رفض الإذن بشكل دائم. يرجى فتح إعدادات التطبيق وتفعيل الإذن يدوياً.',
              'Permission was permanently denied. Please open the app settings and enable it manually.',
            ),
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.t('إلغاء', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text(AppStrings.t('فتح الإعدادات', 'Open settings')),
            ),
          ],
        ),
      ),
    );
  }
}
