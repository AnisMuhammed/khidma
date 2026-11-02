import 'package:flutter/material.dart';

/// تصنيف خدمة معروض في الواجهة.
class ServiceCategory {
  final String name;
  final IconData icon;

  const ServiceCategory({required this.name, required this.icon});
}

/// المصدر الوحيد لقائمة التصنيفات المعروضة.
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
