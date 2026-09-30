import 'package:flutter/material.dart';

/// Disegna solo il tratto alto/sinistro e basso/destro di una card in light.
class AmDiagonalCornerBorder extends StatelessWidget {
  const AmDiagonalCornerBorder({
    required this.child,
    this.radius = 30,
    this.width = 0.65,
    super.key,
  });

  final Widget child;
  final double radius;
  final double width;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return CustomPaint(
      key: const Key('am-diagonal-corner-border-paint'),
      foregroundPainter: light
          ? _DiagonalCornerBorderPainter(
              radius: radius,
              width: width,
              color: const Color(0xFF4F4F51).withValues(alpha: 0.34),
            )
          : null,
      child: child,
    );
  }
}

class _DiagonalCornerBorderPainter extends CustomPainter {
  const _DiagonalCornerBorderPainter({
    required this.radius,
    required this.width,
    required this.color,
  });

  final double radius;
  final double width;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final safeRadius = radius.clamp(0, size.shortestSide / 2).toDouble();
    final horizontalLength = (size.width * 0.40)
        .clamp(safeRadius, size.width)
        .toDouble();
    final verticalLength = (size.height * 0.32)
        .clamp(safeRadius, size.height)
        .toDouble();
    final inset = width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final topLeft = Path()
      ..moveTo(horizontalLength, inset)
      ..lineTo(safeRadius, inset)
      ..quadraticBezierTo(inset, inset, inset, safeRadius)
      ..lineTo(inset, verticalLength);
    final bottomRight = Path()
      ..moveTo(size.width - inset, size.height - verticalLength)
      ..lineTo(size.width - inset, size.height - safeRadius)
      ..quadraticBezierTo(
        size.width - inset,
        size.height - inset,
        size.width - safeRadius,
        size.height - inset,
      )
      ..lineTo(size.width - horizontalLength, size.height - inset);

    canvas
      ..drawPath(topLeft, paint)
      ..drawPath(bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalCornerBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.width != width ||
      oldDelegate.color != color;
}
