import 'package:flutter/material.dart';

enum VehicleHeroWireEdge {
  top,
  bottom,
  nearest;

  Offset on(Rect card, Offset origin) => switch (this) {
    top => card.topCenter,
    bottom => card.bottomCenter,
    nearest => _edgeTowards(card, origin),
  };
}

class VehicleHeroConnector {
  const VehicleHeroConnector(this.origin, this.end, this.color);

  final Offset origin;
  final Offset end;
  final Color color;

  static Path curve(Offset origin, Offset end) => Path()
    ..moveTo(origin.dx, origin.dy)
    ..quadraticBezierTo(origin.dx, (origin.dy + end.dy) / 2, end.dx, end.dy);

  static double length(Offset origin, Offset end) =>
      curve(origin, end).computeMetrics().firstOrNull?.length ?? 0;

  static Offset limitedEnd(Offset origin, Offset desired, double maximum) {
    final length = VehicleHeroConnector.length(origin, desired);
    // The curve's control point scales with its end, preserving its shape when shortened.
    return length <= maximum
        ? desired
        : origin + (desired - origin) * (maximum / length);
  }
}

class VehicleHeroConnectors extends CustomPainter {
  const VehicleHeroConnectors(this.connections);

  final List<VehicleHeroConnector> connections;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final wire in connections) {
      paint
        ..color = wire.color.withValues(alpha: wire.color.a * .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawPath(VehicleHeroConnector.curve(wire.origin, wire.end), paint);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(wire.origin, 3.6, paint);
      paint.color = Colors.white.withValues(alpha: wire.color.a * .8);
      canvas.drawCircle(wire.origin, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(VehicleHeroConnectors oldDelegate) =>
      connections != oldDelegate.connections;
}

Offset _edgeTowards(Rect card, Offset origin) {
  final delta = origin - card.center;
  final x = delta.dx.abs() * card.height;
  final y = delta.dy.abs() * card.width;
  return x > y
      ? Offset(delta.dx < 0 ? card.left : card.right, card.center.dy)
      : Offset(card.center.dx, delta.dy < 0 ? card.top : card.bottom);
}
