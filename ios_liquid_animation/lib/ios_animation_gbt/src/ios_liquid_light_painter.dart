import 'dart:math' as math;

import 'package:flutter/material.dart';

class IosLiquidLightPainter extends CustomPainter {
  final double progress;
  final double intensity;
  final Color color;
  final Alignment origin;
  final BorderRadius borderRadius;

  const IosLiquidLightPainter({
    required this.progress,
    required this.intensity,
    required this.color,
    required this.origin,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0 || size.isEmpty) return;

    final rect = Offset.zero & size;
    final centerAlignment = Alignment.lerp(origin, Alignment.center, progress)!;
    final center = centerAlignment.alongSize(size);
    final radius = math.max(size.width, size.height) * (0.28 + progress * 0.82);
    final glowPaint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.62 * intensity),
          color.withValues(alpha: 0.20 * intensity),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.46, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRRect(borderRadius.toRRect(rect), glowPaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.68 * intensity),
          color.withValues(alpha: 0.08 * intensity),
          color.withValues(alpha: 0.30 * intensity),
        ],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(0.6), edgePaint);
  }

  @override
  bool shouldRepaint(IosLiquidLightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color ||
        oldDelegate.origin != origin ||
        oldDelegate.borderRadius != borderRadius;
  }
}
