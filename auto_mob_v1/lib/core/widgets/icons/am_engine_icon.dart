import 'package:flutter/material.dart';

/// Icona "motore" disegnata a mano (CustomPainter): né Material Icons né
/// Cupertino Icons hanno un glifo dedicato al motore. Stesso contratto
/// visivo di un [Icon] (size + color), usabile sia piccola che come
/// watermark grande.
class AmEngineIcon extends StatelessWidget {
  final double size;
  final Color color;

  const AmEngineIcon({super.key, required this.size, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EngineIconPainter(color: color),
    );
  }
}

class _EngineIconPainter extends CustomPainter {
  final Color color;

  _EngineIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    // Corpo motore (blocco cilindri).
    final body = Rect.fromLTWH(w * 0.15, h * 0.38, w * 0.62, h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * 0.05)),
      fill,
    );

    // Testata (sopra il blocco), solo contorno per distinguerla dal blocco.
    final head = Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.48, h * 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(head, Radius.circular(w * 0.04)),
      stroke,
    );

    // Candele/bulloni sulla testata.
    for (final dx in [0.32, 0.46, 0.60]) {
      canvas.drawCircle(Offset(w * dx, h * 0.29), w * 0.025, fill);
    }

    // Collettore di scarico laterale.
    final manifold = Rect.fromLTWH(w * 0.74, h * 0.48, w * 0.18, h * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(manifold, Radius.circular(w * 0.02)),
      fill,
    );

    // Puleggia/coppa dell'olio (sotto il blocco).
    final pan = Rect.fromLTWH(w * 0.22, h * 0.80, w * 0.48, h * 0.10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pan, Radius.circular(w * 0.02)),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _EngineIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
