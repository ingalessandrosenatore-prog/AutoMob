import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../config/performance_flags.dart';
import 'liquid_glow_painter.dart';
import 'liquid_zoom_config.dart';
import 'liquid_zoom_target.dart';

/// Contenuto della route del morph: la card che si espande dal rect del
/// trigger fino al rect di destinazione, guidata dallo STESSO controller
/// a molla del trigger ([morph]) — la route non ha animazioni proprie.
///
/// Cosa anima, tutto in funzione di `t = morph.value`:
/// - geometria: `Rect.lerp(sourceRect, destRect, t)` senza clampare `t`,
///   così l'overshoot della molla (t > 1) estrapola oltre il rect finale
///   e produce il "rimbalzino" di assestamento;
/// - raggio: dal raggio del trigger (pillola) a [LiquidZoomConfig.destBorderRadius];
/// - fuoco: blur del contenuto `maxBlurSigma * (1 - t)` — sfocato in
///   partenza, a fuoco all'arrivo, e di nuovo sfocato in chiusura;
/// - scrim e ombra: crescono con `t`;
/// - luce: glow bianco additivo che svanisce quando la card è a fuoco.
class LiquidZoomOverlay extends StatefulWidget {
  /// Rect di partenza (il trigger, già sollevato di `liftOffset`).
  final Rect sourceRect;
  final LiquidZoomTarget target;
  final LiquidZoomConfig config;

  /// Controller del morph, posseduto dal trigger (non da questa route).
  final AnimationController morph;

  /// Costruisce il contenuto di destinazione. Il callback `close` DEVE
  /// essere usato per chiudere (mai `Navigator.pop` diretto): esegue la
  /// molla di chiusura e solo alla fine fa il pop della route.
  final Widget Function(BuildContext context, VoidCallback close)
      destinationBuilder;

  /// Notifica il trigger a route chiusa (fa partire il "riatterraggio").
  final VoidCallback onClosed;

  const LiquidZoomOverlay({
    super.key,
    required this.sourceRect,
    required this.target,
    required this.config,
    required this.morph,
    required this.destinationBuilder,
    required this.onClosed,
  });

  @override
  State<LiquidZoomOverlay> createState() => _LiquidZoomOverlayState();
}

class _LiquidZoomOverlayState extends State<LiquidZoomOverlay> {
  bool _closing = false;

  void _close() {
    if (_closing) return;
    _closing = true;
    // La molla di chiusura ha bounce 0: raggiunge lo 0 in modo asintotico,
    // senza mai attraversarlo. Un check `value <= 0` non scatterebbe MAI e
    // la route (con la barriera full-screen) resterebbe montata a
    // intercettare i tap → pagina "freezata". `whenComplete` invece scatta
    // appena la molla si assesta entro tolleranza, a card già invisibile.
    widget.morph
        .animateWith(
          SpringSimulation(
            widget.config.closeSpring,
            widget.morph.value,
            0,
            0,
          ),
        )
        .whenComplete(() {
      if (mounted) Navigator.of(context).pop();
      widget.onClosed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final screen = MediaQuery.of(context).size;
    final destRect = widget.target.resolve(
      source: widget.sourceRect,
      screen: screen,
    );
    final srcRadius =
        config.sourceBorderRadius ?? widget.sourceRect.shortestSide / 2;
    final cardColor = config.cardColor ?? Theme.of(context).colorScheme.surface;

    // Costruito UNA volta e passato come `child` all'AnimatedBuilder: il
    // sottoalbero di destinazione non viene ricostruito a ogni tick.
    final destination = Material(
      type: MaterialType.transparency,
      child: widget.destinationBuilder(context, _close),
    );

    return PopScope(
      // Il back di sistema non deve fare pop secco (lascerebbe il morph a 1
      // e il trigger nascosto per sempre): passa dalla molla di chiusura.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AnimatedBuilder(
        animation: widget.morph,
        child: destination,
        builder: (context, child) {
          final t = widget.morph.value;
          final tc = t.clamp(0.0, 1.0);

          // `t` NON clampato: l'overshoot della molla estrapola il lerp.
          final rect = Rect.lerp(widget.sourceRect, destRect, t)!;
          final radius = lerpDouble(srcRadius, config.destBorderRadius, tc)!;
          final blurSigma = config.maxBlurSigma * (1 - tc);
          // Il contenuto entra nel primo 35% del morph: la card è subito
          // "piena" mentre la geometria è ancora in corsa.
          final contentOpacity = (t / 0.35).clamp(0.0, 1.0);

          return Stack(
            children: [
              // Scrim + barriera: il tap fuori chiude sempre con la molla.
              Positioned.fill(
                child: GestureDetector(
                  onTap: _close,
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: config.scrimColor
                        .withValues(alpha: config.scrimOpacity * tc),
                  ),
                ),
              ),
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                // L'ombra sta FUORI dal clip; il contenuto è SEMPRE disposto
                // alla dimensione finale via OverflowBox e l'espansione la fa
                // il ClipRRect che lo scopre progressivamente. Così niente
                // RenderFlex overflow transitorio durante il morph.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      for (final s in config.shadow)
                        BoxShadow(
                          color: s.color
                              .withValues(alpha: s.color.a * tc),
                          offset: s.offset,
                          blurRadius: s.blurRadius,
                          spreadRadius: s.spreadRadius,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: ColoredBox(
                      // Card opaca: niente trasparenza, per scelta.
                      color: cardColor,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: destRect.width,
                        maxWidth: destRect.width,
                        minHeight: destRect.height,
                        maxHeight: destRect.height,
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: contentOpacity,
                              child: _MessaAFuoco(
                                sigma: blurSigma,
                                child: child!,
                              ),
                            ),
                            if (config.glowEnabled && tc < 1)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: LiquidGlowPainter(
                                      intensity: (1 - tc) * 0.5,
                                      color: config.glowColor,
                                      radius: radius,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Blur di "messa a fuoco" del contenuto, gated dai flag di performance.
///
/// Applica il filtro solo sui device che reggono gli effetti pesanti e solo
/// finché serve davvero: a morph completato (sigma ~0) il filtro viene tolto
/// del tutto, niente saveLayer inutile a riposo.
class _MessaAFuoco extends StatelessWidget {
  final double sigma;
  final Widget child;

  const _MessaAFuoco({required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kHeavyEffects || sigma < 0.1) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }
}
