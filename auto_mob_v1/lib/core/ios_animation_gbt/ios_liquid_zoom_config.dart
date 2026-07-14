import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Curva spring smorzata pensata per una zoom transition in stile iOS.
///
/// A differenza di [Curves.easeOutBack], questa curva usa la risposta di un
/// oscillatore smorzato: accelera rapidamente, supera di poco il valore finale
/// e si assesta senza un rimbalzo vistoso.
class IosDampedSpringCurve extends Curve {
  final double dampingRatio;
  final double angularFrequency;

  const IosDampedSpringCurve({
    this.dampingRatio = 0.72,
    this.angularFrequency = 10.5,
  }) : assert(dampingRatio > 0 && dampingRatio < 1),
       assert(angularFrequency > 0);

  @override
  double transformInternal(double t) {
    if (t == 0 || t == 1) return t;

    final dampedFrequency =
        angularFrequency * math.sqrt(1 - dampingRatio * dampingRatio);
    final envelope = math.exp(-dampingRatio * angularFrequency * t);
    final sineWeight =
        dampingRatio / math.sqrt(1 - dampingRatio * dampingRatio);
    return 1 -
        envelope *
            (math.cos(dampedFrequency * t) +
                sineWeight * math.sin(dampedFrequency * t));
  }
}

/// Tutti i parametri visivi e temporali della liquid zoom transition.
class IosLiquidZoomConfig {
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;
  final Duration liftDuration;
  final Duration liftLeadDuration;
  final Curve openingCurve;
  final Curve closingCurve;
  final double sourceLift;
  final double sourceScale;
  final double backgroundBlur;
  final double contentBlur;
  final double contentStartScale;
  final Color barrierColor;
  final Color surfaceColor;
  final Color lightColor;
  final double lightIntensity;
  final BorderRadius sourceBorderRadius;
  final BorderRadius destinationBorderRadius;
  final bool barrierDismissible;
  final String barrierLabel;
  final bool useRootNavigator;
  final bool captureSource;
  final double maxSnapshotPixelRatio;

  const IosLiquidZoomConfig({
    this.transitionDuration = const Duration(milliseconds: 560),
    this.reverseTransitionDuration = const Duration(milliseconds: 460),
    this.liftDuration = const Duration(milliseconds: 180),
    this.liftLeadDuration = const Duration(milliseconds: 55),
    this.openingCurve = const IosDampedSpringCurve(),
    this.closingCurve = Curves.easeInOutCubic,
    this.sourceLift = 8,
    this.sourceScale = 1.025,
    this.backgroundBlur = 2.5,
    this.contentBlur = 12,
    this.contentStartScale = 0.94,
    this.barrierColor = const Color(0x33000000),
    this.surfaceColor = const Color(0xFFF4F4F5),
    this.lightColor = Colors.white,
    this.lightIntensity = 0.85,
    this.sourceBorderRadius = const BorderRadius.all(Radius.circular(999)),
    this.destinationBorderRadius = const BorderRadius.all(Radius.circular(28)),
    this.barrierDismissible = true,
    this.barrierLabel = 'Chiudi',
    this.useRootNavigator = true,
    this.captureSource = true,
    this.maxSnapshotPixelRatio = 2,
  }) : assert(sourceLift >= 0),
       assert(sourceScale > 0),
       assert(backgroundBlur >= 0),
       assert(contentBlur >= 0),
       assert(contentStartScale > 0),
       assert(lightIntensity >= 0),
       assert(maxSnapshotPixelRatio > 0);

  IosLiquidZoomConfig copyWith({
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    Duration? liftDuration,
    Duration? liftLeadDuration,
    Curve? openingCurve,
    Curve? closingCurve,
    double? sourceLift,
    double? sourceScale,
    double? backgroundBlur,
    double? contentBlur,
    double? contentStartScale,
    Color? barrierColor,
    Color? surfaceColor,
    Color? lightColor,
    double? lightIntensity,
    BorderRadius? sourceBorderRadius,
    BorderRadius? destinationBorderRadius,
    bool? barrierDismissible,
    String? barrierLabel,
    bool? useRootNavigator,
    bool? captureSource,
    double? maxSnapshotPixelRatio,
  }) {
    return IosLiquidZoomConfig(
      transitionDuration: transitionDuration ?? this.transitionDuration,
      reverseTransitionDuration:
          reverseTransitionDuration ?? this.reverseTransitionDuration,
      liftDuration: liftDuration ?? this.liftDuration,
      liftLeadDuration: liftLeadDuration ?? this.liftLeadDuration,
      openingCurve: openingCurve ?? this.openingCurve,
      closingCurve: closingCurve ?? this.closingCurve,
      sourceLift: sourceLift ?? this.sourceLift,
      sourceScale: sourceScale ?? this.sourceScale,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
      contentBlur: contentBlur ?? this.contentBlur,
      contentStartScale: contentStartScale ?? this.contentStartScale,
      barrierColor: barrierColor ?? this.barrierColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      lightColor: lightColor ?? this.lightColor,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      sourceBorderRadius: sourceBorderRadius ?? this.sourceBorderRadius,
      destinationBorderRadius:
          destinationBorderRadius ?? this.destinationBorderRadius,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      barrierLabel: barrierLabel ?? this.barrierLabel,
      useRootNavigator: useRootNavigator ?? this.useRootNavigator,
      captureSource: captureSource ?? this.captureSource,
      maxSnapshotPixelRatio:
          maxSnapshotPixelRatio ?? this.maxSnapshotPixelRatio,
    );
  }
}
