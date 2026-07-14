import 'package:flutter/material.dart';

/// Configurazione estetica e fisica della transizione liquid zoom.
///
/// I default replicano la "zoom transition" di iOS osservata frame per frame:
/// press che solleva leggermente il trigger con una luce bianca, apertura a
/// molla con overshoot finale (il "rimbalzino"), contenuto che parte sfocato
/// e si mette a fuoco, chiusura senza rimbalzo che atterra leggermente sopra
/// il trigger prima che questo si riassesti nella posizione di riposo.
class LiquidZoomConfig {
  /// Durata percepita della molla di apertura (guida tutto il morph).
  final Duration openDuration;

  /// Bounce (0..1) della molla di apertura: 0.2–0.3 dà l'overshoot elastico.
  final double openBounce;

  /// Durata della molla di chiusura. Il bounce è sempre 0: una chiusura che
  /// rimbalza sembrerebbe un errore, non un'animazione.
  final Duration closeDuration;

  /// Scala del trigger a dito premuto (1.0 = press disattivato).
  final double pressScale;

  /// Di quanti px il widget "sale" durante l'apertura: in chiusura la card
  /// atterra leggermente sopra il trigger, che poi si riassesta giù con una
  /// piccola molla (il dettaglio che si nota nel back della zoom transition).
  final double liftOffset;

  /// Luce bianca additiva (BlendMode.plus) sul press e durante il morph.
  final bool glowEnabled;
  final Color glowColor;

  /// Colore della card del morph. `null` → `colorScheme.surface` del tema.
  /// La card è OPACA per scelta: niente trasparenza, solo luce/blur/molla.
  final Color? cardColor;

  /// Raggio degli angoli della card a destinazione.
  final double destBorderRadius;

  /// Raggio del trigger. `null` → pillola/cerchio (lato corto / 2).
  final double? sourceBorderRadius;

  /// Ombra della card (l'alpha viene scalato col progresso del morph, così
  /// l'elevazione "cresce" mentre la card si stacca dal trigger).
  final List<BoxShadow> shadow;

  /// Scrim che oscura la pagina dietro la card.
  final Color scrimColor;
  final double scrimOpacity;

  /// Sigma massimo del blur del contenuto: a morph 0 il contenuto è sfocato
  /// di questo valore, a morph 1 è perfettamente a fuoco. In chiusura la
  /// stessa formula produce la "dissolvenza blur" verso il trigger.
  final double maxBlurSigma;

  const LiquidZoomConfig({
    this.openDuration = const Duration(milliseconds: 450),
    this.openBounce = 0.25,
    this.closeDuration = const Duration(milliseconds: 380),
    this.pressScale = 1.06,
    this.liftOffset = 12.0,
    this.glowEnabled = true,
    this.glowColor = Colors.white,
    this.cardColor,
    this.destBorderRadius = 36.0,
    this.sourceBorderRadius,
    this.shadow = const [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 36,
        offset: Offset(0, 14),
      ),
    ],
    this.scrimColor = Colors.black,
    this.scrimOpacity = 0.32,
    this.maxBlurSigma = 18.0,
  });

  /// Molla principale di apertura (morph e lift del trigger).
  SpringDescription get openSpring => SpringDescription.withDurationAndBounce(
        duration: openDuration,
        bounce: openBounce,
      );

  /// Molla di chiusura: bounce 0, si assesta in modo asintotico senza
  /// oscillare (vedi nota in `LiquidZoomOverlay` sul perché il pop della
  /// route usa `whenComplete` e non un check sul valore).
  SpringDescription get closeSpring => SpringDescription.withDurationAndBounce(
        duration: closeDuration,
        bounce: 0,
      );

  /// Molla del press (veloce, un filo elastica).
  SpringDescription get pressSpring => SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 300),
        bounce: 0.2,
      );

  /// Molla della luce (rapidissima, senza rimbalzo).
  SpringDescription get lightSpring => SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 180),
        bounce: 0,
      );

  /// Molla del "riatterraggio" del trigger a chiusura completata: il bounce
  /// più alto fa affondare il widget un pelo sotto il riposo prima di fermarsi.
  SpringDescription get settleSpring => SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: 0.3,
      );
}
