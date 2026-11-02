import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'
    show FacebookAuth, LoginResult, LoginStatus;
import 'package:google_sign_in/google_sign_in.dart';

import '../core/localization/app_strings.dart';
import '../data/user_session.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'biometric_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final UserRepository _userRepository = UserRepository();

  // ============================================================
  // Email + Password Login
  // ============================================================

  static Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // 1. تسجيل الدخول في Firebase Authentication
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        return false;
      }

      // 2. الحصول على UID من Firebase Authentication
      final String uid = user.uid;

      debugPrint('Firebase UID: $uid');

      // 3. جلب بيانات المستخدم من Firestore
      UserModel? userModel = await _userRepository.getUser(uid);

      if (userModel == null) {
        debugPrint('لم يتم العثور على بيانات المستخدم في Firestore — ننشئ المستند تلقائياً.');

        // إنشاء مستند Firestore تلقائياً للحسابات القديمة
        final displayName = user.displayName?.trim() ?? '';
        final autoName = displayName.isNotEmpty
            ? displayName
            : (email.trim().split('@').first);

        userModel = UserModel(
          id: uid,
          name: autoName,
          email: email.trim(),
          phone: '',
          role: role,
        );
        await _userRepository.createUser(userModel);
        debugPrint('تم إنشاء مستند Firestore للمستخدم: $uid');
      }

      // 4. التأكد من أن نوع الحساب المختار يطابق
      // نوع الحساب الموجود في Firestore
      if (userModel.role != role) {
        debugPrint(
          'نوع الحساب غير مطابق. '
          'Firestore: ${userModel.role} '
          '| Selected: $role',
        );

        await _auth.signOut();
        return false;
      }

      // 5. حفظ بيانات المستخدم في الجلسة مع تعيين الـ UID الحقيقي
      if (userModel.role == 'provider') {
        // تحديث الـ UID في جلسة المزود
        UserSession.currentProvider.id = uid;
        await UserSession.loginAsProvider(
          name: userModel.name,
          emailOrPhone: userModel.email,
          phone: userModel.phone,
        );
      } else {
        // تحديث جلسة العميل مع الـ UID الحقيقي
        UserSession.clientNotifier.value = UserSession.clientNotifier.value.copyWith(
          id: uid,
          name: userModel.name,
          email: userModel.email,
          phone: userModel.phone,
        );
        await UserSession.loginAsClient(
          name: userModel.name,
          emailOrPhone: userModel.email,
          phone: userModel.phone,
        );
      }

      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Email Login Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // Sign Up
  // ============================================================

  static Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      // إنشاء الحساب في Firebase Authentication
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final User? user = credential.user;

      if (user == null) {
        return false;
      }

      // حفظ اسم المستخدم في Firebase Authentication
      await user.updateDisplayName(name.trim());

      // حفظ بيانات المستخدم في Firestore حتى يعمل تسجيل الدخول لاحقاً
      final UserModel userModel = UserModel(
        id: user.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
      );
      await _userRepository.createUser(userModel);

      debugPrint('User saved to Firestore: ${user.uid}');

      // تسجيل الخروج بعد إنشاء الحساب
      // حتى يعود المستخدم إلى شاشة Login
      await _auth.signOut();

      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Sign Up Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // Google Login
  // ============================================================

  /// `google_sign_in` 7.x يشترط استدعاء `initialize()` مرة واحدة قبل أي دالة
  /// أخرى على `GoogleSignIn.instance`، ونصّت الحزمة على أن تجاهل ذلك يجعل
  /// السلوك «غير معرّف». لم يكن مستدعى في المشروع إطلاقاً — وهذا سبب فشل
  /// تسجيل الدخول بجوجل على الهاتف.
  ///
  /// لا نمرّر `serverClientId`: نسخة أندرويد تقرأها تلقائياً من
  /// google-services.json (عميل الويب `client_type: 3`).
  static bool _googleSignInReady = false;

  static Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) return;

    await GoogleSignIn.instance.initialize();

    _googleSignInReady = true;
  }

  static Future<bool> signInWithGoogle({required String role}) async {
    try {
      UserCredential credential;

      // -------------------------
      // Web
      // -------------------------
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        googleProvider.addScope('email');

        credential = await _auth.signInWithPopup(googleProvider);
      }
      // -------------------------
      // Android / iOS
      // -------------------------
      else {
        await _ensureGoogleSignInReady();

        final GoogleSignInAccount googleUser = await GoogleSignIn.instance
            .authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final OAuthCredential googleCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(googleCredential);
      }

      final User? user = credential.user;

      if (user == null) {
        return false;
      }

      final String name = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'مستخدم Google';

      final String email = user.email ?? '';

      if (role == 'provider') {
        await UserSession.loginAsProvider(name: name, emailOrPhone: email);
      } else {
        await UserSession.loginAsClient(name: name, emailOrPhone: email);
      }

      return true;
    } on GoogleSignInException catch (e) {
      // إلغاء المستخدم للنافذة ليس خطأً — نعيد false بلا رسالة خطأ حمراء.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return false;
      }
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // Facebook Login - Web + Android / iOS
  // ============================================================

  static Future<bool> signInWithFacebook({required String role}) async {
    try {
      UserCredential credential;

      // -------------------------
      // Web — كما كان: نافذة Firebase المنبثقة
      // -------------------------
      if (kIsWeb) {
        final FacebookAuthProvider facebookProvider = FacebookAuthProvider();

        facebookProvider.addScope('email');

        facebookProvider.setCustomParameters({'display': 'popup'});

        credential = await _auth.signInWithPopup(facebookProvider);
      }
      // -------------------------
      // Android / iOS — Facebook SDK الأصلي ثم Firebase
      // -------------------------
      else {
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: const ['email', 'public_profile'],
        );

        // إلغاء المستخدم للنافذة ليس خطأً — نعيد false بلا رسالة خطأ حمراء.
        if (result.status == LoginStatus.cancelled ||
            result.status == LoginStatus.operationInProgress) {
          return false;
        }

        final accessToken = result.accessToken;

        if (result.status != LoginStatus.success || accessToken == null) {
          throw FirebaseAuthException(
            code: 'facebook-login-failed',
            message: result.message ?? 'تعذر إكمال تسجيل الدخول بفيسبوك.',
          );
        }

        // التوكن الذي أعطاه فيسبوك يُبادَل بجلسة Firebase Auth.
        final OAuthCredential facebookCredential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        credential = await _auth.signInWithCredential(facebookCredential);
      }

      final User? user = credential.user;

      if (user == null) {
        return false;
      }

      final String name = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!
          : 'مستخدم Facebook';

      final String email = user.email ?? '';

      if (role == 'provider') {
        await UserSession.loginAsProvider(name: name, emailOrPhone: email);
      } else {
        await UserSession.loginAsClient(name: name, emailOrPhone: email);
      }

      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // Biometric Login
  // ============================================================

  static Future<bool> signInWithBiometrics(
    BuildContext context, {
    required String role,
  }) async {
    try {
      final bool authenticated =
          await BiometricService.authenticateWithBiometrics(context);

      if (!authenticated) {
        return false;
      }

      if (role == 'provider') {
        await UserSession.loginAsProvider(
          name: UserSession.currentProvider.name,
          emailOrPhone: UserSession.currentProvider.email,
          phone: UserSession.currentProvider.phone,
        );
      } else {
        await UserSession.loginAsClient(
          name: UserSession.currentUser.name,
          emailOrPhone: UserSession.currentUser.email,
          phone: UserSession.currentUser.phone,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Biometric Login Error: $e');
      return false;
    }
  }

  // ============================================================
  // Forgot Password
  // ============================================================

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ============================================================
  // Logout
  // ============================================================

  static Future<void> signOut() async {
    try {
      await _auth.signOut();

      // `signOut` هي أيضاً من الدوال التي لا يجوز استدعاؤها قبل `initialize()`،
      // ولو لم يُهيَّأ فلا توجد جلسة جوجل أصلاً لنخرج منها.
      if (!kIsWeb && _googleSignInReady) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (e) {
          debugPrint('Google Sign-Out Error: $e');
        }
      }

      await UserSession.logout();
    } catch (e) {
      debugPrint('Sign Out Error: $e');

      await UserSession.logout();
    }
  }

  // ============================================================
  // Firebase Error Messages
  // ============================================================

  /// تحويل كود الخطأ الصادر من Firebase Authentication إلى نص عربي/إنجليزي مترجم
  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AppStrings.t('البريد الإلكتروني غير صحيح', 'Invalid email');

      case 'user-not-found':
        return AppStrings.t(
          'لا يوجد حساب بهذا البريد الإلكتروني',
          'No account found with this email',
        );

      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.t(
          'البريد الإلكتروني أو كلمة المرور غير صحيحة',
          'Incorrect email or password',
        );

      case 'user-disabled':
        return AppStrings.t('تم تعطيل هذا الحساب', 'This account is disabled');

      case 'too-many-requests':
        return AppStrings.t(
          'تم إجراء محاولات كثيرة، حاول لاحقًا',
          'Too many attempts, please try again later',
        );

      case 'email-already-in-use':
        return AppStrings.t(
          'البريد الإلكتروني مستخدم بالفعل',
          'This email is already in use',
        );

      case 'weak-password':
        return AppStrings.t(
          'كلمة المرور ضعيفة، استخدم كلمة مرور أقوى',
          'Weak password, please use a stronger password',
        );

      case 'network-request-failed':
        return AppStrings.t(
          'تحقق من اتصال الإنترنت',
          'Check your internet connection',
        );

      case 'operation-not-allowed':
        return AppStrings.t(
          'طريقة المصادقة غير مفعلة في Firebase',
          'This sign-in method is not enabled in Firebase',
        );

      case 'popup-closed-by-user':
        return AppStrings.t(
          'تم إغلاق نافذة تسجيل الدخول',
          'The sign-in window was closed',
        );

      case 'popup-blocked':
        return AppStrings.t(
          'المتصفح منع نافذة تسجيل الدخول',
          'The browser blocked the sign-in window',
        );

      case 'cancelled-popup-request':
        return AppStrings.t(
          'تم إلغاء عملية تسجيل الدخول',
          'Sign-in was cancelled',
        );

      case 'account-exists-with-different-credential':
        return AppStrings.t(
          'يوجد حساب بهذا البريد بطريقة تسجيل دخول أخرى',
          'An account with this email already exists using another sign-in method',
        );

      default:
        return e.message ??
            AppStrings.t(
              'حدث خطأ في المصادقة',
              'An authentication error occurred',
            );
    }
  }
}

extension FirebaseAuthExceptionX on FirebaseAuthException {
  String get userMessage => AuthService.getErrorMessage(this);
}
