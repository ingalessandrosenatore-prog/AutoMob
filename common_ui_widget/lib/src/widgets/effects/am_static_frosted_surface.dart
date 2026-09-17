import 'dart:ui';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

SmoothRectangleBorder _shape(double radius, {BorderSide? side}) =>
    SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: 0.8,
      ),
      side: side ?? BorderSide.none,
    );

/// Superficie translucida statica condivisa da dialog e menu contestuali.
/// Mantiene il backdrop blur, ma non monta shader o rifrazione Liquid Glass.
class AmStaticFrostedSurface extends StatelessWidget {
  const AmStaticFrostedSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.showShadow = true,
    this.surfaceKey,
    this.blurKey,
    this.decorationKey,
  });

  final double borderRadius;
  final Widget child;
  final bool showShadow;
  final Key? surfaceKey;
  final Key? blurKey;
  final Key? decorationKey;

  static List<Color> fillColors(Brightness brightness) => switch (brightness) {
    Brightness.light => const [
      Color.fromRGBO(255, 255, 255, 0.782),
      Color.fromRGBO(250, 250, 252, 0.748),
      Color.fromRGBO(241, 241, 242, 0.714),
    ],
    Brightness.dark => const [
      Color.fromRGBO(44, 44, 46, 0.714),
      Color.fromRGBO(28, 28, 30, 0.680),
      Color.fromRGBO(18, 18, 20, 0.646),
    ],
  };

  static Color borderColor(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color.fromRGBO(255, 255, 255, 0.72),
    Brightness.dark => const Color.fromRGBO(255, 255, 255, 0.14),
  };

  static List<BoxShadow> shadows(Brightness brightness) => switch (brightness) {
    Brightness.light => const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.12),
        offset: Offset(0, 10),
        blurRadius: 24,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.08),
        offset: Offset(0, 3),
        blurRadius: 8,
      ),
    ],
    Brightness.dark => const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.35),
        offset: Offset(0, 12),
        blurRadius: 30,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.20),
        offset: Offset(0, 4),
        blurRadius: 10,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      key: surfaceKey,
      decoration: ShapeDecoration(
        shadows: showShadow ? shadows(brightness) : const [],
        shape: _shape(borderRadius),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: _shape(borderRadius)),
        child: BackdropFilter(
          key: blurKey,
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            key: decorationKey,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: fillColors(brightness),
              ),
              shape: _shape(
                borderRadius,
                side: BorderSide(color: borderColor(brightness), width: 0.75),
              ),
            ),
            child: CustomPaint(
              foregroundPainter: _HighlightPainter(
                brightness: brightness,
                borderRadius: borderRadius,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  const _HighlightPainter({
    required this.brightness,
    required this.borderRadius,
  });

  final Brightness brightness;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final isDark = brightness == Brightness.dark;
    final radius = borderRadius.clamp(0, size.shortestSide / 2).toDouble();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: isDark ? 0.28 : 0.85),
          Colors.white.withValues(alpha: isDark ? 0.22 : 0.65),
          Colors.white.withValues(alpha: isDark ? 0.08 : 0.20),
          Colors.transparent,
        ],
        stops: const [0, 0.35, 0.72, 1],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(0.75, size.height - radius)
      ..lineTo(0.75, radius)
      ..quadraticBezierTo(0.75, 0.75, radius, 0.75)
      ..lineTo(size.width - radius, 0.75)
      ..quadraticBezierTo(size.width - 0.75, 0.75, size.width - 0.75, radius);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) =>
      oldDelegate.brightness != brightness ||
      oldDelegate.borderRadius != borderRadius;
}
