import 'package:flutter/material.dart';

/// تصنيف خدمة معروض في الواجهة.
class ServiceCategory {
  final String name;
  final IconData icon;

  const ServiceCategory({required this.name, required this.icon});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      name: json['name']?.toString() ?? '',
      icon: parseCategoryIcon(json['icon']?.toString() ?? json['name']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  static IconData parseCategoryIcon(String iconStr) {
    final clean = iconStr.toLowerCase().trim();
    switch (clean) {
      case 'water_drop':
      case 'plumbing':
      case 'سباكة':
        return Icons.plumbing_rounded;
      case 'electric_bolt':
      case 'electrical_services':
      case 'كهرباء':
        return Icons.electrical_services_rounded;
      case 'cleaning_services':
      case 'cleaning':
      case 'تنظيف':
        return Icons.cleaning_services_rounded;
      case 'format_paint':
      case 'paint':
      case 'دهان':
        return Icons.format_paint_rounded;
      case 'carpenter':
      case 'carpentry':
      case 'نجارة':
        return Icons.carpenter_rounded;
      case 'design_services':
      case 'decor':
      case 'ديكور':
        return Icons.design_services_rounded;
      case 'ac_unit':
      case 'ac':
      case 'تكييف':
        return Icons.ac_unit_rounded;
      case 'local_shipping':
      case 'نقل أثاث':
      case 'نقل':
        return Icons.local_shipping_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }
}

/// المصدر الاحتياطي الأولي لقائمة التصنيفات المعروضة (Fallback / Offline Cache).
// تُستخدم في الصفحة الرئيسية وصفحة الخدمات معاً.
const List<ServiceCategory> serviceCategories = [
  ServiceCategory(name: 'سباكة', icon: Icons.plumbing_rounded),
  ServiceCategory(name: 'كهرباء', icon: Icons.electrical_services_rounded),
  ServiceCategory(name: 'تنظيف', icon: Icons.cleaning_services_rounded),
  ServiceCategory(name: 'دهان', icon: Icons.format_paint_rounded),
  ServiceCategory(name: 'نجارة', icon: Icons.carpenter_rounded),
  ServiceCategory(name: 'ديكور', icon: Icons.design_services_rounded),
  ServiceCategory(name: 'تكييف', icon: Icons.ac_unit_rounded),
  ServiceCategory(name: 'نقل أثاث', icon: Icons.local_shipping_rounded),
];
