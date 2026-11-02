import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../core/localization/app_strings.dart';

/// Biometric Authentication Service
/// يدعم التحقق الحقيقي عبر بصمة الإصبع أو التعرف على الوجه باستخدام LocalAuthentication
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// التحقق من دعم الجهاز للبصمة والمصادقة البيومترية
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// الحصول على أنواع المصادقة البيومترية المتوفرة بالجهاز (بصمة / وجه)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// التحقق الحقيقي من بصمة الإصبع أو الوجه
  static Future<bool> authenticateWithBiometrics(BuildContext context) async {
    try {
      final bool canAuth = await isBiometricAvailable();
      if (!canAuth) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.t(
                  'المصادقة البيومترية غير مدعومة على هذا الجهاز',
                  'Biometric authentication is not supported on this device',
                ),
              ),
            ),
          );
        }
        return false;
      }

      return await _auth.authenticate(
        localizedReason: AppStrings.t(
          'يرجى تأكيد هويتك لتسجيل الدخول السريع إلى تطبيق خِدْمَة',
          'Please verify your identity to sign in to Khidma app',
        ),
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      debugPrint('LocalAuthException: ${e.code} - ${e.description}');
      return false;
    } on PlatformException catch (e) {
      debugPrint('PlatformException: $e');
      return false;
    }
  }
}
