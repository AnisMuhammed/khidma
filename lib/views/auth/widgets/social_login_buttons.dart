import 'dart:math' as math;

import 'package:flutter/material.dart';

/// شعار Google الرسمي (حرف G بألوانه الأربعة).
///
/// Material Icons ما فيه أيقونة للشعار الحقيقي (الموجودة `g_mobiledata` مجرد
/// حرف G عادي بلون واحد)، فالشعار مرسوم هنا بالكود بنفس ألوان Google الرسمية.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  // ألوان Google الرسمية.
  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.24;
    final radius = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // الزوايا بالدرجات: 0 = اتجاه الساعة 3، والموجب باتجاه عقارب الساعة.
    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
        rect,
        _rad(start),
        _rad(sweep),
        false,
        paint..color = color,
      );
    }

    arc(-160, 120, _red); // القوس العلوي
    arc(-25, 65, _blue); // القوس الأيمن
    arc(40, 100, _green); // القوس السفلي
    arc(140, 60, _yellow); // القوس الأيسر

    // الشريط الأفقي الأزرق — هو ما يميّز حرف G عن حرف O.
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        center.dx + size.width / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// زر مربّع بأيقونة المنصّة ولونها الرسمي.
class SocialSquareButton extends StatelessWidget {
  final Widget icon;
  final Color backgroundColor;
  final Color? borderColor;
  final String tooltip;
  final VoidCallback? onTap;

  const SocialSquareButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.tooltip,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.5,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: borderColor == null
                    ? null
                    : Border.all(color: borderColor!, width: 1.4),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// مربّعا Google و Facebook جنباً إلى جنب، بنفس الحجم وبنفس المسافة بينهما.
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;

  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialSquareButton(
          tooltip: 'Google',
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderColor: isDark ? const Color(0xFF3C4043) : const Color(0xFFDADCE0),
          onTap: onGoogleTap,
          icon: const GoogleLogo(size: 30),
        ),

        const SizedBox(width: 20),

        SocialSquareButton(
          tooltip: 'Facebook',
          backgroundColor: const Color(0xFF1877F2),
          onTap: onFacebookTap,
          icon: const Icon(
            Icons.facebook_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ],
    );
  }
}
