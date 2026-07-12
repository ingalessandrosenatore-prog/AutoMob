import 'package:flutter/material.dart';

/// Versione **piatta** (senza shader / senza backdrop filter) della forma
/// vetro dei pulsanti, per quando non vogliamo il liquid glass reale
/// (device che non reggono, `kHeavyEffects == false`).
///
/// Resa: un gradiente radiale che parte dal [color] al centro e **schiarisce
/// verso i bordi** (il tipico highlight del vetro), con una [opacity]
/// complessiva per alleggerire il look su device deboli. Nessun campionamento
/// dello sfondo → costo GPU ~zero e, a differenza dell'`OCLiquidGlass` orfano,
/// non "scivola" durante lo scroll.
///
/// Pensata come drop-in di `OCLiquidGlass` nei pulsanti: stessa API di base
/// ([color], [borderRadius], [width], [height], [child]).
class AmFlatGlass extends StatelessWidget {
  /// Colore base della forma (centro del gradiente). Ne viene rispettata
  /// anche l'eventuale trasparenza (alpha).
  final Color color;

  /// Quanto schiarire il colore verso i bordi: 0 = nessuna schiaritura,
  /// 1 = bianco pieno. Interpola verso il bianco, quindi alza anche un po'
  /// l'alpha ai bordi dando l'anello di luce del vetro.
  final double edgeLighten;

  /// Opacità complessiva applicata al gradiente (0..1). Sotto 1 rende la
  /// forma un po' più trasparente ("un po' di opacity" sui device deboli).
  final double opacity;

  final double borderRadius;
  final double? width;
  final double? height;
  final Widget? child;

  const AmFlatGlass({
    super.key,
    required this.color,
    this.edgeLighten = 0.35,
    this.opacity = 1.0,
    this.borderRadius = 0,
    this.width,
    this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double o = opacity.clamp(0.0, 1.0);
    // Colore dei bordi: il [color] schiarito verso il bianco.
    final Color bordo = Color.lerp(color, Colors.white, edgeLighten.clamp(0.0, 1.0))!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: RadialGradient(
          radius: 0.95,
          colors: [
            color.withValues(alpha: color.a * o),
            bordo.withValues(alpha: bordo.a * o),
          ],
        ),
      ),
      child: child,
    );
  }
}
