import 'package:flutter/material.dart';

/// Fallback piatto condiviso della forma di vetro quando gli effetti pesanti
/// sono disattivati.
///
/// Il gradiente parte dal [color] fornito dal chiamante e schiarisce verso il
/// bordo: non usa un [Border], perciò il bordo luminoso resta morbido sia sui
/// cerchi sia sulle pillole. Non campiona lo sfondo e non usa shader liquid.
class AmFlatGlass extends StatelessWidget {
  /// Tinta centrale. L'alpha ricevuto viene rispettato anche ai bordi.
  final Color color;

  /// 0 = nessuna schiaritura del bordo, 1 = bianco alla stessa opacità.
  final double edgeLighten;

  /// Opacità complessiva della forma, senza alterare la tinta di partenza.
  final double opacity;

  final double borderRadius;
  final double? width;
  final double? height;
  final BoxShadow? shadow;
  final Widget? child;

  const AmFlatGlass({
    super.key,
    required this.color,
    this.edgeLighten = 0.72,
    this.opacity = 1.0,
    this.borderRadius = 0,
    this.width,
    this.height,
    this.shadow,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Tre passaggi ben distinti: il fallback deve leggere come un
    // riempimento sfumato, non come un colore pieno con un bordo appena
    // accennato.

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(boxShadow: shadow == null ? null : [shadow!]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          // Non usiamo [RadialGradient] in una [BoxDecoration]: per Flutter
          // il suo raggio è basato sul lato corto e su una pillola resterebbe
          // circolare. Questo painter scala il raggio sull'asse X.
          painter: _EllipticalGlassGradientPainter(
            borderRadius: borderRadius,
            colors: [
              color,
              color.withValues(alpha: 0.7),
              Colors.white.withValues(alpha: 0.8),
              Colors.white,
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Superficie piatta per dialog e bottom sheet.
///
/// A differenza di [AmFlatGlass], non disegna una sfumatura ellittica: un popup
/// e' rettangolare e deve mantenere un riempimento uniforme. Non riceve
/// dimensioni, quindi si adatta naturalmente al proprio [child].
class AmFlatPopUp extends StatelessWidget {
  /// Unica tinta della superficie. Viene usata come riempimento del popup.
  final Color color;
  final BorderRadius borderRadius;
  final List<BoxShadow>? boxShadow;
  final Widget child;

  const AmFlatPopUp({
    super.key,
    required this.color,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

class _EllipticalGlassGradientPainter extends CustomPainter {
  final double borderRadius;
  final List<Color> colors;

  const _EllipticalGlassGradientPainter({
    required this.borderRadius,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final side = size.shortestSide;
    final radius = Radius.circular(borderRadius.clamp(0, side / 2));
    final paint = Paint()
      ..shader =
          RadialGradient(
            radius: 0.9,
            colors: colors,
            stops: const [0.0, 0.52, 0.92, 1.0],
          ).createShader(
            Rect.fromCenter(center: Offset.zero, width: side, height: side),
          );

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, radius));
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / side, 1);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: side, height: side),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EllipticalGlassGradientPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.colors != colors;
}
