import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

/// Curvatura condivisa dalle superfici non circolari dell'app meccanico.
const mechanicCornerSmoothing = 0.6;

/// Target minimo comune: 48 dp copre anche il requisito Android più ampio.
const mechanicMinimumTouchTarget = 48.0;

SmoothRectangleBorder mechanicSmoothShape({
  required double radius,
  BorderSide side = BorderSide.none,
}) => SmoothRectangleBorder(
  side: side,
  borderRadius: SmoothBorderRadius(
    cornerRadius: radius,
    cornerSmoothing: mechanicCornerSmoothing,
  ),
);
