import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'widgets/account_type_button.dart';
import 'widgets/social_login_buttons.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  String _accountType = 'client';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // Email Login
  // ============================================================

  Future<void> _login() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await AuthService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _accountType,
      );

      if (!mounted) return;

      if (success) {
        if (_accountType == 'provider') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.providerDashboard,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.main,
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showError(e.userMessage);
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceAll('Exception: ', '');
      _showError(msg);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // Google Login
  // ============================================================

  Future<void> _googleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await AuthService.signInWithGoogle(
        role: _accountType,
      );

      if (!mounted) return;

      if (success) {
        if (_accountType == 'provider') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.providerDashboard,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.main,
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showError(e.userMessage);
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceAll('Exception: ', '');
      _showError(msg);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // Facebook Login
  // ============================================================

  Future<void> _facebookLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await AuthService.signInWithFacebook(
        role: _accountType,
      );

      if (!mounted) return;

      if (success) {
        if (_accountType == 'provider') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.providerDashboard,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.main,
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showError(e.userMessage);
    } catch (e) {
      if (!mounted) return;

      _showError(
        AppStrings.t(
          'تعذر تسجيل الدخول باستخدام Facebook',
          'Could not sign in with Facebook',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // Biometric Login
  // ============================================================

  Future<void> _biometricLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool success = await AuthService.signInWithBiometrics(
        context,
        role: _accountType,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.main,
          (route) => false,
        );
      } else {
        _showError(
          AppStrings.t('تعذر التحقق بالبصمة', 'Biometric verification failed'),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        AppStrings.t(
          'تعذر استخدام المصادقة البيومترية',
          'Could not use biometric authentication',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/logo/khidma_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.home_repair_service_rounded,
                                    size: 48,
                                    color: colors.primary,
                                  ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        AppStrings.tr('app_name'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        AppStrings.t(
                          'تسجيل الدخول إلى حسابك',
                          'Sign in to your account',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 30),

                      // Account Type
                      Text(
                        AppStrings.t('نوع الحساب', 'Account Type'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: AccountTypeButton(
                              title: AppStrings.t('عميل', 'Client'),
                              icon: Icons.person_rounded,
                              selected: _accountType == 'client',
                              onTap: () {
                                setState(() {
                                  _accountType = 'client';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AccountTypeButton(
                              title: AppStrings.t(
                                'مزود خدمة',
                                'Service Provider',
                              ),
                              icon: Icons.engineering_rounded,
                              selected: _accountType == 'provider',
                              onTap: () {
                                setState(() {
                                  _accountType = 'provider';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: AppStrings.t(
                            'البريد الإلكتروني',
                            'Email',
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.t(
                              'أدخل البريد الإلكتروني',
                              'Enter your email',
                            );
                          }

                          if (!value.contains('@')) {
                            return AppStrings.t(
                              'أدخل بريدًا إلكترونيًا صحيحًا',
                              'Enter a valid email address',
                            );
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: AppStrings.t('كلمة المرور', 'Password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.t(
                              'أدخل كلمة المرور',
                              'Enter your password',
                            );
                          }

                          if (value.length < 6) {
                            return AppStrings.t(
                              'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                              'Password must be at least 6 characters',
                            );
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.forgotPassword,
                                  );
                                },
                          child: Text(
                            AppStrings.t('نسيت كلمة المرور؟', 'Forgot password?'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      // Login
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(AppStrings.tr('login')),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              AppStrings.t('أو', 'OR'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google + Facebook — مربّعان بنفس الحجم وألوانهما الرسمية
                      SocialLoginButtons(
                        onGoogleTap: _isLoading ? null : _googleLogin,
                        onFacebookTap: _isLoading ? null : _facebookLogin,
                      ),

                      const SizedBox(height: 12),

                      // Biometric
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _biometricLogin,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          AppStrings.t(
                            'تسجيل الدخول بالبصمة',
                            'Biometric Login',
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Signup
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.t('ليس لديك حساب؟', "Don't have an account?"),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.signup,
                                    );
                                  },
                            child: Text(
                              AppStrings.t('إنشاء حساب', 'Sign Up'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}
