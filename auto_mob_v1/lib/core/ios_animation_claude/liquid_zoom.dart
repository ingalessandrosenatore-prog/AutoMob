import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../services/haptic_service.dart';
import 'liquid_glow_painter.dart';
import 'liquid_zoom_config.dart';
import 'liquid_zoom_overlay.dart';
import 'liquid_zoom_target.dart';

/// Trigger della "liquid zoom transition" (la zoom transition di iOS).
///
/// Avvolge un widget sorgente qualsiasi (bottone, card, chip…) e, al tap,
/// lo fa morfare in un widget di destinazione (pagina, modale o popup, a
/// seconda del [target]) con la sequenza osservata su iOS:
///
/// 1. **press** — il trigger si ingrandisce un filo ([LiquidZoomConfig.pressScale])
///    e si accende una luce bianca additiva;
/// 2. **rilascio** — parte UNA molla ([LiquidZoomConfig.openSpring]) che guida
///    tutto: il trigger sale di [LiquidZoomConfig.liftOffset] px e svanisce,
///    mentre la card cresce dal suo rect verso la destinazione con overshoot
///    finale; il contenuto parte sfocato e si mette a fuoco;
/// 3. **chiusura** — molla senza rimbalzo: la card si ricontrae (sfocandosi)
///    fino a un punto leggermente SOPRA il trigger — dov'era salito in
///    apertura — poi il trigger riappare e "riatterra" con una piccola molla.
///
/// Uso:
/// ```dart
/// LiquidZoom(
///   target: const LiquidZoomTarget.modal(heightFactor: 0.6),
///   destinationBuilder: (context, close) => MiaPagina(onDone: close),
///   child: const MioBottone(), // solo visuale: il tap lo gestisce LiquidZoom
/// )
/// ```
///
/// Note d'uso:
/// - il [child] non deve avere un suo `onTap`: il gesto lo gestisce questo
///   widget (come in `AmPullDownLG`);
/// - per chiudere dalla destinazione usare SEMPRE il callback `close`
///   ricevuto dal builder, mai `Navigator.pop` diretto;
/// - il trigger non va smontato mentre la route è aperta: il controller del
///   morph vive qui e la card aperta lo sta ascoltando.
class LiquidZoom extends StatefulWidget {
  /// Widget sorgente, puramente visuale (il tap lo intercetta [LiquidZoom]).
  final Widget child;

  /// Contenuto di destinazione; `close` esegue la chiusura animata.
  final Widget Function(BuildContext context, VoidCallback close)
      destinationBuilder;

  /// Geometria di arrivo: pagina, modale o popup ancorato.
  final LiquidZoomTarget target;

  final LiquidZoomConfig config;

  /// Callback opzionali sull'apertura e sulla chiusura completata.
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;

  const LiquidZoom({
    super.key,
    required this.child,
    required this.destinationBuilder,
    this.target = const LiquidZoomTarget.page(),
    this.config = const LiquidZoomConfig(),
    this.onOpened,
    this.onClosed,
  });

  @override
  State<LiquidZoom> createState() => _LiquidZoomState();
}

class _LiquidZoomState extends State<LiquidZoom>
    with TickerProviderStateMixin {
  /// Scala del trigger sul press (riposo = 1).
  late final AnimationController pressCtrl;

  /// Luce bianca sul press (0..1).
  late final AnimationController lightCtrl;

  /// Progresso del morph (0 chiuso, 1 aperto). Unbounded: la molla deve
  /// poter superare 1 per dare l'overshoot.
  late final AnimationController morphCtrl;

  /// Salita del trigger (0 a riposo, 1 sollevato di `liftOffset`). Resta a 1
  /// per tutta la vita della route e torna a 0 col "riatterraggio" finale.
  late final AnimationController liftCtrl;

  final GlobalKey _triggerKey = GlobalKey();
  Rect _sourceRect = Rect.zero;

  LiquidZoomConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    pressCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    lightCtrl = AnimationController(vsync: this, value: 0.0);
    morphCtrl = AnimationController.unbounded(vsync: this, value: 0.0);
    liftCtrl = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    pressCtrl.dispose();
    lightCtrl.dispose();
    morphCtrl.dispose();
    liftCtrl.dispose();
    super.dispose();
  }

  /// La route è aperta (o si sta aprendo/chiudendo): ignora nuovi tap.
  bool get _isBusy => morphCtrl.isAnimating || morphCtrl.value > 0.05;

  void _misuraTrigger() {
    final box =
        _triggerKey.currentContext!.findRenderObject() as RenderBox;
    _sourceRect = box.localToGlobal(Offset.zero) & box.size;
  }

  void _onPress() {
    if (_isBusy) return;
    _misuraTrigger();
    pressCtrl.animateWith(
      SpringSimulation(
          _config.pressSpring, pressCtrl.value, _config.pressScale, 0),
    );
    lightCtrl.animateWith(
      SpringSimulation(_config.lightSpring, lightCtrl.value, 0.6, 0),
    );
  }

  void _onCancel() {
    pressCtrl.animateWith(
      SpringSimulation(_config.pressSpring, pressCtrl.value, 1, 0),
    );
    lightCtrl.animateWith(
      SpringSimulation(_config.lightSpring, lightCtrl.value, 0, 0),
    );
  }

  void _onRelease() {
    if (_isBusy) return;
    AmHaptics.selection();
    _onCancel(); // press e luce tornano a riposo
    morphCtrl.animateWith(
      SpringSimulation(_config.openSpring, morphCtrl.value, 1, 0),
    );
    liftCtrl.animateWith(
      SpringSimulation(_config.openSpring, liftCtrl.value, 1, 0),
    );
    _apriRoute();
    widget.onOpened?.call();
  }

  /// Chiamato dall'overlay a route ormai chiusa: il trigger, riapparso
  /// sollevato di `liftOffset`, riatterra nella posizione di riposo.
  void _onOverlayClosed() {
    if (mounted) {
      liftCtrl.animateWith(
        SpringSimulation(_config.settleSpring, liftCtrl.value, 0, 0),
      );
    }
    widget.onClosed?.call();
  }

  void _apriRoute() {
    // Il morph parte dal rect del trigger già sollevato: è lì che la card
    // "nasce" in apertura e "atterra" in chiusura (leggermente sopra il
    // bottone, come nella zoom transition originale).
    final lifted = _sourceRect.shift(Offset(0, -_config.liftOffset));
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'chiudi',
      barrierColor: Colors.transparent,
      // Nessuna transizione di route: l'animazione è tutta del controller
      // a molla. Una transizione di default (200ms) si sommerebbe e terrebbe
      // la barriera a intercettare tap quando il morph è già finito.
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return LiquidZoomOverlay(
          sourceRect: lifted,
          target: widget.target,
          config: _config,
          morph: morphCtrl,
          destinationBuilder: widget.destinationBuilder,
          onClosed: _onOverlayClosed,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      onTapDown: (_) => _onPress(),
      onTapUp: (_) => _onRelease(),
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation:
            Listenable.merge([pressCtrl, lightCtrl, morphCtrl, liftCtrl]),
        child: widget.child,
        builder: (context, child) {
          // Il trigger sparisce quasi subito (la card gli nasce sopra) e
          // riappare solo nell'ultimo quarto della chiusura, già sollevato.
          final visibile = (1 - morphCtrl.value * 4).clamp(0.0, 1.0);
          // Non clampato: l'overshoot della molla di riatterraggio fa
          // affondare il trigger un pelo sotto il riposo prima di fermarsi.
          final salita = -_config.liftOffset * liftCtrl.value;

          return Transform.translate(
            offset: Offset(0, salita),
            child: Transform.scale(
              scale: pressCtrl.value,
              child: Opacity(
                opacity: visibile,
                child: Stack(
                  children: [
                    child!,
                    if (_config.glowEnabled)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: LiquidGlowPainter(
                              intensity: lightCtrl.value,
                              color: _config.glowColor,
                              radius: _config.sourceBorderRadius,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
