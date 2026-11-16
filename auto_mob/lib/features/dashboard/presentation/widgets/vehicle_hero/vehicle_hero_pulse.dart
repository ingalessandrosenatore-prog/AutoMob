import 'dart:math' as math;

import 'package:flutter/material.dart';

class VehicleHeroWire {
  const VehicleHeroWire(this.origin, this.end, this.start, this.duration);

  final Offset origin;
  final Offset end;
  final double start;
  final double duration;
}

class VehicleHeroPulse extends CustomPainter {
  VehicleHeroPulse({
    required this.animation,
    required this.wires,
    required this.accent,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final List<VehicleHeroWire> wires;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final spark = Color.lerp(accent, Colors.white, .6)!;
    for (final wire in wires) {
      final progress = ((animation.value - wire.start) / wire.duration).clamp(
        0.0,
        1.0,
      );
      if (progress == 0) continue;
      final origin = wire.origin;
      final end = wire.end;
      final elbow = Offset.lerp(origin, end, .70)!;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(
          origin.dx + (end.dx - origin.dx) * .34,
          origin.dy + (end.dy - origin.dy) * .07,
          elbow.dx,
          end.dy,
        )
        ..lineTo(end.dx, end.dy);
      final metric = path.computeMetrics().first;
      final distance = metric.length * progress;
      final visible = metric.extractPath(0, distance);
      final glow = Paint()
        ..color = accent.withValues(alpha: .25)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      final trace = Paint()
        ..color = accent.withValues(alpha: .80)
        ..strokeWidth = 1.45
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(visible, glow);
      canvas.drawPath(visible, trace);
      canvas.drawCircle(
        origin,
        9.0,
        Paint()
          ..color = accent.withValues(alpha: .36)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(origin, 4.5, Paint()..color = accent);
      canvas.drawCircle(origin, 2, Paint()..color = spark);
      if (progress < 1) {
        final pulse = metric.extractPath(math.max(0, distance - 21), distance);
        canvas.drawPath(pulse, trace..color = spark);
        final tip = metric.getTangentForOffset(distance)!.position;
        canvas.drawCircle(tip, 3, Paint()..color = spark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant VehicleHeroPulse oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.wires != wires ||
      oldDelegate.accent != accent;
}
