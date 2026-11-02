class CategoryHelper {
  /// توحيد مسمى المهنة والتصنيف لمطابقة دقيقة ومرنة بين العميل والمزود
  static String normalizeCategory(String input) {
    final clean = input.trim().toLowerCase();
    if (clean.contains('كهرب')) {
      return 'كهرباء';
    }
    if (clean.contains('سباك') || clean.contains('صحي')) {
      return 'سباكة';
    }
    if (clean.contains('دهان') ||
        clean.contains('طلاء') ||
        clean.contains('بوية')) {
      return 'دهان';
    }
    if (clean.contains('نظاف') || clean.contains('تنظيف')) {
      return 'تنظيف';
    }
    if (clean.contains('نجار') ||
        clean.contains('خشب') ||
        clean.contains('أثاث')) {
      return 'نجارة';
    }
    if (clean.contains('ديكور') ||
        clean.contains('تشطيب') ||
        clean.contains('جبس')) {
      return 'ديكور';
    }
    return clean;
  }

  /// فحص هل المزود يطابق تصنيف الخدمة المطلوبة
  static bool matchesCategory({
    required String? providerProfession,
    required String? providerCategory,
    required String? targetCategory,
  }) {
    if (targetCategory == null || targetCategory.trim().isEmpty) {
      return true;
    }
    final targetNorm = normalizeCategory(targetCategory);
    final provNorm = normalizeCategory(providerProfession ?? '');
    final catNorm = normalizeCategory(providerCategory ?? '');

    return provNorm.contains(targetNorm) ||
        targetNorm.contains(provNorm) ||
        catNorm.contains(targetNorm) ||
        targetNorm.contains(catNorm);
  }
}
