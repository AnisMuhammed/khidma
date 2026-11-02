import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppImageHelper {
  /// عرض صورة تعمل على كافة المنصات (Flutter Web, Android, iOS, Windows)
  ///
  /// [cacheWidth] / [cacheHeight] يحدّدان دقة فك الترميز بالبكسل الفيزيائي بدل
  /// مقاس الصورة الأصلي. مرّرهما في القوائم والشبكات: صورة 4000px معروضة في
  /// مربع 120px تُفكّ الآن بحجم المربع، وهذا يقلّل الذاكرة وزمن الإطار.
  static Widget buildImage({
    required String? path,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    BorderRadius? borderRadius,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    if (path == null || path.trim().isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    final trimmed = path.trim();

    Widget imageWidget;

    // حالة 1: إذا كنا على المتصفح (Flutter Web) أو الرابط يبدأ بـ http أو blob
    if (kIsWeb ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('blob:')) {
      imageWidget = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ?? _defaultErrorPlaceholder(),
      );
    }
    // حالة 2: إذا كانت من الأصول (Assets)
    else if (trimmed.startsWith('assets/')) {
      imageWidget = Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ?? _defaultErrorPlaceholder(),
      );
    }
    // حالة 3: ملف محلي على Android أو iOS أو Windows Desktop
    else {
      try {
        final file = File(trimmed);
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: (context, error, stackTrace) =>
              placeholder ?? _defaultErrorPlaceholder(),
        );
      } catch (e) {
        imageWidget = placeholder ?? _defaultErrorPlaceholder();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }

    return imageWidget;
  }

  /// إرجاع ImageProvider يعمل على كل المنصات بما فيها Flutter Web
  static ImageProvider? getImageProvider(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();

    if (kIsWeb ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('blob:')) {
      return NetworkImage(trimmed);
    }

    if (trimmed.startsWith('assets/')) {
      return AssetImage(trimmed);
    }

    try {
      final file = File(trimmed);
      return FileImage(file);
    } catch (_) {
      return null;
    }
  }

  static Widget _defaultErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
    );
  }
}
