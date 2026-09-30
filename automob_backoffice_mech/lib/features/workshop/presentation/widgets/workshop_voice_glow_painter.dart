import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Disegna una massa luminosa che sale dal bordo inferiore del microfono.
///
/// L'ampiezza della voce controlla estensione, altezza e luminosità; [phase]
/// aggiunge un lento movimento laterale per evitare una forma statica.
class WorkshopVoiceGlowPainter extends CustomPainter {
  const WorkshopVoiceGlowPainter({
    required this.color,
    required this.phase,
    required this.amplitude,
  });

  final Color color;
  final double phase;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final voice = amplitude.clamp(0.0, 1.0).toDouble();
    final wave = math.sin(phase * math.pi * 2);
    final shortestSide = math.min(size.width, size.height);
    final radius = shortestSide * (0.52 + voice * 0.30);
    final paint = Paint()..blendMode = BlendMode.plus;

    canvas.saveLayer(Offset.zero & size, Paint());
    _drawGlow(
      canvas,
      paint,
      center: Offset(
        size.width * (0.50 + wave * 0.12),
        size.height * (0.97 - voice * 0.16),
      ),
      radius: radius,
      coreAlpha: 0.34 + voice * 0.42,
    );
    _drawGlow(
      canvas,
      paint,
      center: Offset(
        size.width * (0.18 - wave * 0.06),
        size.height * (1.01 - voice * 0.08),
      ),
      radius: radius * 0.72,
      coreAlpha: 0.18 + voice * 0.28,
    );
    _drawGlow(
      canvas,
      paint,
      center: Offset(
        size.width * (0.82 - wave * 0.05),
        size.height * (1.02 - voice * 0.10),
      ),
      radius: radius * 0.68,
      coreAlpha: 0.16 + voice * 0.26,
    );
    canvas.restore();
  }

  void _drawGlow(
    Canvas canvas,
    Paint paint, {
    required Offset center,
    required double radius,
    required double coreAlpha,
  }) {
    paint.shader = RadialGradient(
      colors: [
        color.withValues(alpha: coreAlpha),
        color.withValues(alpha: coreAlpha * 0.48),
        Colors.transparent,
      ],
      stops: const [0, 0.42, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(WorkshopVoiceGlowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.phase != phase ||
      oldDelegate.amplitude != amplitude;
}
