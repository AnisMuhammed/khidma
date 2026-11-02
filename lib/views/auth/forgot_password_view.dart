import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false; // لعرض شاشة النجاح

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      // تم الإرسال بنجاح — اعرض شاشة النجاح
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message;
      switch (e.code) {
        case 'invalid-email':
          message = AppStrings.t(
            'البريد الإلكتروني غير صحيح',
            'The email address is not valid',
          );
          break;
        case 'user-not-found':
          // Firebase الحديثة لا ترجع هذا الخطأ — لكن نتعامل معه احتياطاً
          message = AppStrings.t(
            'لا يوجد حساب مرتبط بهذا البريد الإلكتروني',
            'No account is linked to this email address',
          );
          break;
        case 'network-request-failed':
          message = AppStrings.t(
            'تعذر الاتصال بالإنترنت، تحقق من اتصالك وحاول مرة أخرى',
            'Could not connect to the internet. Check your connection and try again',
          );
          break;
        case 'too-many-requests':
          message = AppStrings.t(
            'لقد حاولت كثيراً، يرجى الانتظار قليلاً ثم المحاولة مجدداً',
            'Too many attempts. Please wait a moment and try again',
          );
          break;
        default:
          message =
              e.message ??
              AppStrings.t(
                'حدث خطأ أثناء إرسال رسالة الاستعادة',
                'An error occurred while sending the recovery email',
              );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(
              'حدث خطأ غير متوقع، حاول مرة أخرى',
              'An unexpected error occurred, please try again',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('استعادة كلمة المرور', 'Reset Password')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: _emailSent
                  ? _buildSuccessWidget(colors, theme)
                  : _buildFormWidget(colors, theme),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // واجهة النموذج
  // ============================================================
  Widget _buildFormWidget(ColorScheme colors, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الأيقونة
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 44,
                color: colors.primary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            AppStrings.t('نسيت كلمة المرور؟', 'Forgot your password?'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            AppStrings.t(
              'أدخل بريدك الإلكتروني المسجّل وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.',
              'Enter your registered email address and we will send you a link to reset your password.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.65),
            ),
          ),

          const SizedBox(height: 32),

          // حقل البريد الإلكتروني
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetEmail(),
            decoration: InputDecoration(
              labelText: AppStrings.t('البريد الإلكتروني', 'Email address'),
              hintText: 'example@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.t(
                  'أدخل البريد الإلكتروني',
                  'Enter the email address',
                );
              }
              final email = value.trim();
              if (!email.contains('@') || !email.contains('.')) {
                return AppStrings.t(
                  'أدخل بريداً إلكترونياً صحيحاً',
                  'Enter a valid email address',
                );
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // زر الإرسال
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendResetEmail,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isLoading
                    ? AppStrings.t('جاري الإرسال...', 'Sending...')
                    : AppStrings.t(
                        'إرسال رابط الاستعادة',
                        'Send reset link',
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // العودة لتسجيل الدخول
          TextButton.icon(
            onPressed: _isLoading ? null : _goToLogin,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(
              AppStrings.t('العودة لتسجيل الدخول', 'Back to login'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // واجهة النجاح بعد الإرسال
  // ============================================================
  Widget _buildSuccessWidget(ColorScheme colors, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // أيقونة النجاح
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 50,
              color: Colors.green,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          AppStrings.t('تم إرسال الرابط! ✉️', 'Link sent! ✉️'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          AppStrings.t(
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى:\n${_emailController.text.trim()}',
            'A password reset link was sent to:\n${_emailController.text.trim()}',
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.70),
          ),
        ),

        const SizedBox(height: 12),

        // تلميح للمستخدم
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.t(
                    'إذا لم يصل الإيميل خلال دقيقتين، تحقق من مجلد البريد غير المرغوب فيه (Spam).',
                    'If the email does not arrive within two minutes, check your spam folder.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // زر العودة لتسجيل الدخول
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _goToLogin,
            icon: const Icon(Icons.login_rounded),
            label: Text(
              AppStrings.t('العودة لتسجيل الدخول', 'Back to login'),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // زر إعادة الإرسال
        TextButton(
          onPressed: () => setState(() {
            _emailSent = false;
          }),
          child: Text(
            AppStrings.t(
              'لم يصلني الإيميل، أعد الإرسال',
              'I did not receive the email, resend it',
            ),
          ),
        ),
      ],
    );
  }
}
