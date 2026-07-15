import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import 'am_flat_glass.dart';

/// Versione "smart" della singola **forma** di vetro: sostituisce SOLO
/// l'[OCLiquidGlass], non il gruppo.
///
/// - [liquid] = true  → [OCLiquidGlass] con `enabled: true`. Si registra nel
///   [OCLiquidGlassGroup] antenato e viene rifratto dallo shader.
/// - [liquid] = false → un semplice [Container] con lo **stesso** sfondo
///   ([color]), dimensioni, raggio e ombra. Niente shader → costo GPU ~zero.
///
/// IMPORTANTE: il gruppo ([OCLiquidGlassGroup]) NON sta qui dentro. Resta
/// esterno (uno solo, così le forme vicine si fondono) e va a sua volta messo
/// in un `if` sullo stesso flag, così quando [liquid] è false non c'è alcun
/// backdrop filter.
class SmartGlass extends StatelessWidget {
  /// true = forma liquid glass reale, false = container statico leggero.
  final bool liquid;

  final double? width;
  final double? height;

  /// Sfondo: tinta del vetro quando [liquid] è true, colore pieno del
  /// container quando è false.
  final Color color;

  final double borderRadius;
  final BoxShadow? shadow;

  final Widget? child;

  const SmartGlass({
    super.key,
    required this.liquid,
    this.width,
    this.height,
    this.color = Colors.transparent,
    this.borderRadius = 0.0,
    this.shadow,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (liquid) {
      return OCLiquidGlass(
        enabled: true,
        width: width,
        height: height,
        color: color,
        borderRadius: borderRadius,
        shadow: shadow,
        child: child,
      );
    }

    return AmFlatGlass(
      width: width,
      height: height,
      color: color,
      borderRadius: borderRadius,
      shadow: shadow,
      child: child,
    );
  }
}
