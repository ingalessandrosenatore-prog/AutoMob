import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Effetto "invito al tap": **bordo luminoso rotante** (sweep/conic gradient)
/// + **alone pulsante** (breathing glow) attorno al [child].
///
/// Pensato per essere ultra-leggero (120fps anche su device vecchi):
/// - il bordo è un solo `drawRRect` in stroke con uno `SweepGradient` (nessun
///   blur shader, nessun `saveLayer`);
/// - l'alone è una sola `BoxShadow` animata;
/// - tutto isolato in `RepaintBoundary`, quindi l'animazione continua non fa
///   ripingere il resto della card.
class PulsingGlowBorder extends StatefulWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final Duration duration;

  const PulsingGlowBorder({
    super.key,
    required this.child,
    this.color = const Color(0xFFFF6B00),
    this.borderRadius = 20,
    this.strokeWidth = 2,
    this.duration = const Duration(milliseconds: 5000),
  });

  @override
  State<PulsingGlowBorder> createState() => _PulsingGlowBorderState();
}

class _PulsingGlowBorderState extends State<PulsingGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value;
          // respiro 0..1 con curva ease-in-out (coseno)
          final breath = 0.5 - 0.5 * math.cos(t * 2 * math.pi);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.12 + 0.33 * breath),
                  blurRadius: 6 + 12 * breath,
                  spreadRadius: 0.5 + 1.5 * breath,
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: _RotatingBorderPainter(
                angle: t * 2 * math.pi,
                color: widget.color,
                radius: widget.borderRadius,
                strokeWidth: widget.strokeWidth,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _RotatingBorderPainter extends CustomPainter {
  final double angle;
  final Color color;
  final double radius;
  final double strokeWidth;

  _RotatingBorderPainter({
    required this.angle,
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    // Sweep gradient: un arco luminoso che ruota lungo tutto il bordo.
    final shader = SweepGradient(
      colors: [
        color .withValues(alpha: 0.0),
        color.withValues(alpha: 0.0),
        color,
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 0.78, 1.0],
      transform: GradientRotation(angle),
    ).createShader(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = shader;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_RotatingBorderPainter old) =>
      old.angle != angle ||
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
