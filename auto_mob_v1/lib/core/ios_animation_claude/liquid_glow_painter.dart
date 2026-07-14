import 'package:flutter/widgets.dart';

/// Luce "Apple" additiva: gradiente radiale disegnato in [BlendMode.plus]
/// dentro un rounded-rect. È la stessa luce che si vede sul press del trigger
/// e sulla card mentre il morph è in corsa (svanisce quando arriva a fuoco).
class LiquidGlowPainter extends CustomPainter {
  /// 0 = spenta, 1 = piena. Scala l'alpha di tutto il gradiente.
  final double intensity;
  final Color color;

  /// Raggio degli angoli. `null` → pillola (altezza / 2).
  final double? radius;

  LiquidGlowPainter({
    required this.intensity,
    required this.color,
    this.radius,
  });

  @override
  void paint(Canvas c, Size s) {
    if (intensity <= 0) return;

    final rect = Offset.zero & s;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.50 * intensity),
          color.withValues(alpha: 0.40 * intensity),
          color.withValues(alpha: 0.30 * intensity),
        ],
      ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius ?? s.height / 2),
    );
    c.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(LiquidGlowPainter old) =>
      old.intensity != intensity || old.color != color || old.radius != radius;
}
