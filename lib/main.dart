import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

import 'views/auth/login_view.dart';
import 'views/onboarding/onboarding_view.dart';
import 'views/splash/splash_view.dart';
import 'views/auth/signup_view.dart';
import 'views/auth/forgot_password_view.dart';

import 'views/main_navigation_view.dart';

import 'views/profile/edit_profile_view.dart';
import 'views/orders/orders_view.dart';
import 'views/profile/notifications_view.dart';
import 'views/profile/settings_view.dart';
import 'views/profile/language_view.dart';
import 'views/profile/theme_view.dart';

import 'views/orders/order_details_view.dart';
import 'views/orders/order_confirmation_view.dart';
import 'views/orders/payment_view.dart';

import 'views/provider/provider_setup_view.dart';
import 'views/provider/provider_dashboard_view.dart';
import 'views/provider/provider_profile_client_view.dart';
import 'views/booking/booking_schedule_view.dart';
import 'views/chat/chat_view.dart';

import 'views/orders/order_success_view.dart';
import 'views/location/location_view.dart';
import 'views/rating/rating_view.dart';

import 'views/services/services_view.dart';
import 'views/services/service_details_view.dart';
import 'views/services/search_view.dart';

import 'views/provider/provider_schedule_view.dart';
import 'views/provider/provider_orders_view.dart';
import 'views/provider/provider_profile_view.dart';
import 'views/provider/provider_previous_work_view.dart';
import 'views/provider/provider_chat_view.dart';

import 'services/local_db_service.dart';
import 'repositories/favorite_repository.dart';
import 'core/theme/app_theme_manager.dart';
import 'core/localization/app_language_manager.dart';
import 'data/user_session.dart';
import 'services/sqlite_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // SQLite Database (Local SQL DB)
  await SqliteService.init();

  // Local Preferences & Cache
  await LocalDbService.init();

  // Favorites (Local DB & SQLite Sync)
  await FavoriteRepository.init();

  // Notifications
  await NotificationService.init();

  // Theme
  AppThemeManager.init();

  // Language
  AppLanguageManager.init();

  // User Session
  await UserSession.init();

  runApp(const KhidmaApp());
}

class KhidmaApp extends StatelessWidget {
  const KhidmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeManager.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: AppLanguageManager.localeNotifier,
          builder: (context, locale, _) {
            final isRtl = locale.languageCode == 'ar';

            return MaterialApp(
              debugShowCheckedModeBanner: false,

              title: locale.languageCode == 'ar' ? 'خِدْمَة' : 'Khidma',

              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,

              locale: locale,
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              builder: (context, child) {
                return Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                );
              },

              initialRoute: AppRoutes.splash,

              routes: {
                AppRoutes.splash: (context) => const SplashView(),

                AppRoutes.onboarding: (context) => const OnboardingView(),

                AppRoutes.login: (context) => const LoginView(),

                AppRoutes.signup: (context) => const SignupView(),

                AppRoutes.forgotPassword: (context) =>
                    const ForgotPasswordView(),

                AppRoutes.editProfile: (context) => const EditProfileView(),

                AppRoutes.orders: (context) => const OrdersView(),
                AppRoutes.notifications: (context) => const NotificationsView(),

                AppRoutes.settings: (context) => const SettingsView(),

                AppRoutes.language: (context) => const LanguageView(),

                AppRoutes.theme: (context) => const ThemeView(),

                AppRoutes.orderDetails: (context) => const OrderDetailsView(),

                AppRoutes.orderConfirmation: (context) =>
                    const OrderConfirmationView(),

                AppRoutes.payment: (context) => const PaymentView(),

                AppRoutes.main: (context) => const MainNavigationView(),

                AppRoutes.providerSetup: (context) => const ProviderSetupView(),

                AppRoutes.providerClient: (context) =>
                    const ProviderProfileClientView(),

                AppRoutes.booking: (context) => const BookingScheduleView(),

                AppRoutes.chat: (context) => const ChatView(),

                AppRoutes.providerDashboard: (context) =>
                    const ProviderDashboardView(),

                AppRoutes.orderSuccess: (context) => const OrderSuccessView(),

                AppRoutes.services: (context) => const ServicesView(),

                AppRoutes.search: (context) => const SearchView(),

                AppRoutes.location: (context) => const LocationView(),

                AppRoutes.serviceDetails: (context) {
                  return const ServiceDetailsView();
                },

                AppRoutes.providerSchedule: (context) =>
                    const ProviderScheduleView(),

                AppRoutes.providerOrders: (context) =>
                    const ProviderOrdersView(),

                AppRoutes.providerEditProfile: (context) =>
                    const ProviderProfileView(),

                AppRoutes.providerPreviousWork: (context) =>
                    const ProviderPreviousWorkView(),

                AppRoutes.providerChatInbox: (context) =>
                    const ProviderChatView(),

                AppRoutes.rating: (context) => const RatingView(),
              },
            );
          },
        );
      },
    );
  }
}
