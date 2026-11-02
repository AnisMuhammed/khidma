import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String provider;
  final double rating;
  final int reviews;
  final double price;
  final String icon;
  final String? imageAsset;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.provider,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.icon,
    this.imageAsset,
  });

  IconData get iconData {
    switch (icon) {
      case 'water_drop':
      case 'plumbing':
        return Icons.water_drop_rounded;
      case 'electric_bolt':
      case 'electric':
        return Icons.electric_bolt_rounded;
      case 'format_paint':
      case 'paint':
        return Icons.format_paint_rounded;
      case 'cleaning_services':
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'carpenter':
      case 'carpentry':
        return Icons.carpenter_rounded;
      case 'home_work':
      case 'decor':
        return Icons.home_work_rounded;
      case 'ac_unit':
      case 'ac':
        return Icons.ac_unit_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : 4.8,
      reviews: json['reviews'] is int ? json['reviews'] as int : 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      icon: json['icon']?.toString() ?? 'build',
      imageAsset: json['imageAsset']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'provider': provider,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'icon': icon,
      'imageAsset': imageAsset,
    };
  }
}
