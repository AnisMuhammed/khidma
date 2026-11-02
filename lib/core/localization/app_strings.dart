import 'app_language_manager.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_name': 'خِدْمَة',
      'app_tagline': 'منصة الخدمات المنزلية الذكية',
      'home': 'الرئيسية',
      'favorites': 'المفضلة',
      'orders': 'الطلبات',
      'cart': 'السلة',
      'profile': 'حسابي',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'theme': 'المظهر',
      'light_theme': 'فاتح',
      'dark_theme': 'داكن',
      'system_theme': 'النظام',
      'logout': 'تسجيل الخروج',
      'search_hint': 'ابحث عن سباك، كهربائي، تنظيف...',
      'services': 'الخدمات',
      'popular_services': 'الخدمات الشائعة',
      'providers': 'مزودو الخدمة',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب جديد',
      'biometric_login': 'الدخول بالبصمة',
      'order_now': 'طلب الخدمة',
      'new_order': 'جديد',
      'accepted_order': 'مقبول',
      'in_progress_order': 'قيد التنفيذ',
      'completed_order': 'مكتمل',
      'rate_service': 'تقييم الخدمة',
    },
    'en': {
      'app_name': 'Khidma',
      'app_tagline': 'Smart Home Services Platform',
      'home': 'Home',
      'favorites': 'Favorites',
      'orders': 'Orders',
      'cart': 'Cart',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'light_theme': 'Light',
      'dark_theme': 'Dark',
      'system_theme': 'System',
      'logout': 'Logout',
      'search_hint': 'Search for plumber, electrician, cleaning...',
      'services': 'Services',
      'popular_services': 'Popular Services',
      'providers': 'Service Providers',
      'login': 'Login',
      'signup': 'Sign Up',
      'biometric_login': 'Biometric Login',
      'order_now': 'Request Service',
      'new_order': 'New',
      'accepted_order': 'Accepted',
      'in_progress_order': 'In Progress',
      'completed_order': 'Completed',
      'rate_service': 'Rate Service',
    },
  };

  static String tr(String key, {String? languageCode}) {
    final lang = languageCode ?? AppLanguageManager.currentCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['ar']?[key] ?? key;
  }

  /// ترجمة مباشرة للنصوص المكتوبة داخل الواجهات: النص العربي ثم مقابله الإنجليزي.
  ///
  /// الاستخدام: `AppStrings.t('الإعدادات', 'Settings')`
  /// تُرجع العربي عندما تكون لغة التطبيق عربية، والإنجليزي فيما عدا ذلك.
  static String t(String ar, String en) =>
      AppLanguageManager.isArabic ? ar : en;
}
