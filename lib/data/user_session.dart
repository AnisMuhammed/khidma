import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/category_helper.dart';
import '../models/user_model.dart';
import '../models/provider_model.dart';
import '../services/firestore_service.dart';
import '../services/sqlite_service.dart';

class UserSession {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserRole = 'user_role';

  static const String _keyClientName = 'client_name';
  static const String _keyClientEmail = 'client_email';
  static const String _keyClientPhone = 'client_phone';
  static const String _keyClientImage = 'client_image';

  static const String _keyProviderName = 'provider_name';
  static const String _keyProviderEmail = 'provider_email';
  static const String _keyProviderPhone = 'provider_phone';
  static const String _keyProviderProfession = 'provider_profession';
  static const String _keyProviderCategory = 'provider_category';
  static const String _keyProviderBio = 'provider_bio';
  static const String _keyProviderYears = 'provider_years';
  static const String _keyProviderImage = 'provider_image';
  static const String _keyProviderAvailable = 'provider_available';
  static const String _keyProviderVerified = 'provider_verified';
  static const String _keyProviderCertificates = 'provider_certificates';
  static const String _keyProviderWorks = 'provider_works';

  static bool isLoggedIn = false;
  static String currentUserRole = 'client';

  // جلسة العميل الحالية
  static final ValueNotifier<UserModel> clientNotifier =
      ValueNotifier<UserModel>(
        UserModel(
          id: 'client_guest',
          name: 'عميل',
          email: '',
          phone: '',
          role: 'client',
        ),
      );

  // جلسة مزود الخدمة الحالية
  static final ValueNotifier<ProviderModel> providerNotifier =
      ValueNotifier<ProviderModel>(
        ProviderModel(
          id: 'provider_guest',
          name: 'مزود خدمة',
          profession: 'كهربائي',
          serviceCategory: 'كهرباء',
          experienceYears: 1,
          rating: 5.0,
          completedJobs: 0,
          bio: '',
        ),
      );

  static UserModel get currentClient => clientNotifier.value;
  static UserModel get currentUser => clientNotifier.value;
  static ProviderModel get currentProvider => providerNotifier.value;

  /// تهيئة الجلسة واسترجاع البيانات المخزنة من قاعدة البيانات المحلية (Local Database)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      currentUserRole = prefs.getString(_keyUserRole) ?? 'client';

      // استرجاع بيانات العميل
      final clientName = prefs.getString(_keyClientName);
      final clientEmail = prefs.getString(_keyClientEmail);
      final clientPhone = prefs.getString(_keyClientPhone);
      final clientImage = prefs.getString(_keyClientImage);

      if (clientName != null || clientEmail != null || clientImage != null) {
        clientNotifier.value = clientNotifier.value.copyWith(
          name: clientName ?? clientNotifier.value.name,
          email: clientEmail ?? clientNotifier.value.email,
          phone: clientPhone ?? clientNotifier.value.phone,
          profileImagePath: clientImage,
        );
      }

      // استرجاع بيانات مزود الخدمة
      final provider = providerNotifier.value;
      final providerName = prefs.getString(_keyProviderName);
      final providerEmail = prefs.getString(_keyProviderEmail);
      final providerPhone = prefs.getString(_keyProviderPhone);
      final providerProfession = prefs.getString(_keyProviderProfession);
      final providerCategory = prefs.getString(_keyProviderCategory);
      final providerBio = prefs.getString(_keyProviderBio);
      final providerYears = prefs.getInt(_keyProviderYears);
      final providerImage = prefs.getString(_keyProviderImage);
      final providerAvail = prefs.getBool(_keyProviderAvailable);
      final providerVerified = prefs.getBool(_keyProviderVerified);
      final providerCerts = prefs.getString(_keyProviderCertificates);
      final providerWorks = prefs.getString(_keyProviderWorks);

      if (providerName != null) provider.name = providerName;
      if (providerEmail != null) provider.email = providerEmail;
      if (providerPhone != null) provider.phone = providerPhone;
      if (providerProfession != null) {
        provider.profession = providerProfession;
        provider.serviceCategory =
            providerCategory ??
            CategoryHelper.normalizeCategory(providerProfession);
      }
      if (providerCategory != null) provider.serviceCategory = providerCategory;
      if (providerBio != null) provider.bio = providerBio;
      if (providerYears != null) provider.experienceYears = providerYears;
      if (providerImage != null) provider.profileImagePath = providerImage;
      if (providerAvail != null) provider.isAvailable = providerAvail;
      if (providerVerified != null) provider.isVerified = providerVerified;

      if (providerCerts != null) {
        try {
          final list = jsonDecode(providerCerts) as List;
          provider.certificates = list.map((e) => e.toString()).toList();
        } catch (_) {}
      }

      if (providerWorks != null) {
        try {
          final list = jsonDecode(providerWorks) as List;
          provider.previousWorks = list.map((w) {
            final m = w as Map<String, dynamic>;
            return PreviousWork(
              title: m['title']?.toString() ?? '',
              description: m['description']?.toString() ?? '',
              beforeImagePath: m['beforeImagePath']?.toString(),
              afterImagePath: m['afterImagePath']?.toString(),
            );
          }).toList();
        } catch (_) {}
      }

      providerNotifier.value = provider;
    } catch (e) {
      debugPrint('Error initializing UserSession: $e');
    }
  }

  /// تسجيل دخول كعميل ببيانات الاعتماد
  static Future<void> loginAsClient({
    required String emailOrPhone,
    String? name,
    String? phone,
  }) async {
    isLoggedIn = true;
    currentUserRole = 'client';

    final current = clientNotifier.value;
    String newEmail = current.email;
    String newPhone = phone ?? current.phone;
    String newName = name ?? current.name;

    if (emailOrPhone.contains('@')) {
      newEmail = emailOrPhone;
      if ((name == null || name.isEmpty) &&
          (newName == 'محمد القادري' || newName.isEmpty)) {
        final prefix = emailOrPhone.split('@').first;
        if (prefix.isNotEmpty) {
          newName = prefix;
        }
      }
    } else {
      newPhone = emailOrPhone;
    }

    clientNotifier.value = current.copyWith(
      email: newEmail,
      phone: newPhone,
      name: newName,
    );
    await _saveClientToLocalDb();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, 'client');
  }

  /// تسجيل دخول كمزود خدمة ببيانات الاعتماد
  static Future<void> loginAsProvider({
    required String emailOrPhone,
    String? name,
    String? phone,
  }) async {
    isLoggedIn = true;
    currentUserRole = 'provider';

    final provider = providerNotifier.value;
    if (name != null && name.isNotEmpty) provider.name = name;
    if (phone != null && phone.isNotEmpty) provider.phone = phone;

    if (emailOrPhone.contains('@')) {
      provider.email = emailOrPhone;
      if (provider.name == 'أحمد محمد' || provider.name.isEmpty) {
        final prefix = emailOrPhone.split('@').first;
        if (prefix.isNotEmpty) {
          provider.name = prefix;
        }
      }
    } else {
      provider.phone = emailOrPhone;
    }
    providerNotifier.value = provider;
    await _saveProviderToLocalDb();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, 'provider');
  }

  /// تسجيل حساب جديد كعميل
  static Future<void> registerClient({
    required String name,
    required String email,
    required String phone,
    String? profileImagePath,
  }) async {
    isLoggedIn = true;
    currentUserRole = 'client';

    clientNotifier.value = UserModel(
      id: 'client_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'عميل جديد' : name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: 'client',
      profileImagePath: profileImagePath,
    );
    await _saveClientToLocalDb();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, 'client');
  }

  /// تسجيل حساب جديد كمزود خدمة
  static Future<void> registerProvider({
    required String name,
    required String email,
    required String phone,
    String profession = 'مزود خدمة محترف',
    String? profileImagePath,
  }) async {
    isLoggedIn = true;
    currentUserRole = 'provider';

    final provider = providerNotifier.value;
    provider.name = name.trim().isEmpty ? 'مزود خدمة جديد' : name.trim();
    provider.email = email.trim();
    provider.phone = phone.trim();
    provider.profession = profession;
    if (profileImagePath != null) {
      provider.profileImagePath = profileImagePath;
    }
    providerNotifier.value = provider;
    await _saveProviderToLocalDb();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, 'provider');
  }

  /// تعديل وتحديث الملف الشخصي للعميل يدوياً مع حفظ دائم في قاعدة البيانات
  static void updateClientProfile({
    required String name,
    required String email,
    required String phone,
    String? profileImagePath,
  }) {
    clientNotifier.value = clientNotifier.value.copyWith(
      name: name,
      email: email,
      phone: phone,
      profileImagePath:
          profileImagePath ?? clientNotifier.value.profileImagePath,
    );
    _saveClientToLocalDb();
  }

  /// تعديل وتحديث الملف الشخصي لمزود الخدمة يدوياً مع حفظ دائم في قاعدة البيانات
  static Future<void> updateProviderProfile({
    required String name,
    required String profession,
    required String bio,
    required int experienceYears,
    required String phone,
    String? serviceCategory,
    String? email,
    String? profileImagePath,
  }) async {
    final current = providerNotifier.value;
    providerNotifier.value = current.copyWith(
      name: name,
      profession: profession,
      serviceCategory:
          serviceCategory ?? CategoryHelper.normalizeCategory(profession),
      bio: bio,
      experienceYears: experienceYears,
      phone: phone,
      email: (email != null && email.isNotEmpty) ? email : current.email,
      profileImagePath: profileImagePath ?? current.profileImagePath,
    );
    await _saveProviderToLocalDb();
  }

  /// حفظ وتحديث الملف الكامل لمزود الخدمة
  static Future<void> saveProviderFullProfile(ProviderModel provider) async {
    providerNotifier.value = provider;
    await _saveProviderToLocalDb();
  }

  /// تبديل حالة توفر مزود الخدمة (متاح / غير متاح) باستجابة فورية (0ms)
  static Future<void> toggleProviderAvailability(bool available) async {
    final current = providerNotifier.value;
    // تحديث فوري للواجهة بإنشاء كائن جديد يستشعره ValueNotifier فورياً دون أي تأخير
    providerNotifier.value = current.copyWith(isAvailable: available);

    // حفظ في قاعدة البيانات المحلية والسحابية في الخلفية
    _saveProviderToLocalDb();
    if (current.id.isNotEmpty && current.id != 'provider_guest') {
      FirestoreService.saveProvider(providerNotifier.value);
    }
  }

  /// تسجيل الخروج
  static Future<void> logout() async {
    isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  /// حفظ بيانات العميل محلياً وسحابياً
  static Future<void> _saveClientToLocalDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final client = clientNotifier.value;
      await prefs.setString(_keyClientName, client.name);
      await prefs.setString(_keyClientEmail, client.email);
      await prefs.setString(_keyClientPhone, client.phone);
      if (client.profileImagePath != null) {
        await prefs.setString(_keyClientImage, client.profileImagePath!);
      }

      // حفظ في Firestore و SQLite
      await FirestoreService.saveUser(client);
      await SqliteService.insertUser(client);
    } catch (e) {
      debugPrint('Error saving client to local DB: $e');
    }
  }

  /// حفظ بيانات مزود الخدمة محلياً وسحابياً
  static Future<void> _saveProviderToLocalDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = providerNotifier.value;
      await prefs.setString(_keyProviderName, provider.name);
      await prefs.setString(_keyProviderEmail, provider.email);
      await prefs.setString(_keyProviderPhone, provider.phone);
      await prefs.setString(_keyProviderProfession, provider.profession);
      await prefs.setString(_keyProviderCategory, provider.serviceCategory);
      await prefs.setString(_keyProviderBio, provider.bio);
      await prefs.setInt(_keyProviderYears, provider.experienceYears);
      await prefs.setBool(_keyProviderAvailable, provider.isAvailable);
      await prefs.setBool(_keyProviderVerified, provider.isVerified);
      await prefs.setString(
        _keyProviderCertificates,
        jsonEncode(provider.certificates),
      );
      final worksJson = jsonEncode(
        provider.previousWorks
            .map(
              (w) => {
                'title': w.title,
                'description': w.description,
                'beforeImagePath': w.beforeImagePath,
                'afterImagePath': w.afterImagePath,
              },
            )
            .toList(),
      );
      await prefs.setString(_keyProviderWorks, worksJson);

      if (provider.profileImagePath != null) {
        await prefs.setString(_keyProviderImage, provider.profileImagePath!);
      }

      // حفظ في Firestore و SQLite
      await FirestoreService.saveProvider(provider);
      await SqliteService.insertOrUpdateProvider(provider);
    } catch (e) {
      debugPrint('Error saving provider to local DB: $e');
    }
  }
}
