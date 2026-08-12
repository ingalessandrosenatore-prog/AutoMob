import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../../../core/widgets/mechanic_shapes.dart';
import '../bloc/voice_search_state.dart';

/// Microfono della Home: espone solo l'intento di tap e renderizza lo stato.
///
/// È [StatefulWidget] perché possiede il controller della sola animazione
/// locale del glow. L'avvio e l'arresto del riconoscimento restano nel BLoC
/// della pagina: il pulsante non contiene business logic.
class WorkshopVoiceButton extends StatefulWidget {
  const WorkshopVoiceButton({
    super.key,
    required this.state,
    required this.onPressed,
  });

  final VoiceSearchState state;
  final VoidCallback onPressed;

  @override
  State<WorkshopVoiceButton> createState() => _WorkshopVoiceButtonState();
}

class _WorkshopVoiceButtonState extends State<WorkshopVoiceButton>
    with SingleTickerProviderStateMixin {
  /// Controller lento e ciclico: i suoi tick vengono consumati soltanto dal
  /// [AnimatedBuilder] del [CustomPaint], non dall'albero della Home.
  late final AnimationController _glowController;
  bool? _disableAnimations;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations == disableAnimations) return;
    _disableAnimations = disableAnimations;
    _syncGlowAnimation(widget.state.isListening);
  }

  @override
  void didUpdateWidget(covariant WorkshopVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isListening != widget.state.isListening) {
      _syncGlowAnimation(widget.state.isListening);
    }
  }

  void _syncGlowAnimation(bool isListening) {
    if (_disableAnimations == true) {
      // A fixed phase preserves the glow without continuous motion when the
      // platform requests reduced motion.
      _glowController
        ..stop()
        ..value = 0;
      return;
    }
    if (isListening) {
      _glowController.repeat();
    } else {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final shape = mechanicSmoothShape(radius: 37);
    final state = widget.state;
    final active = state.isVisible;
    final glowDuration = _disableAnimations == true
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Semantics(
      button: true,
      label: state.isListening
          ? 'Interrompi ricerca vocale'
          : active
          ? 'Chiudi ricerca vocale'
          : 'Avvia ricerca vocale',
      child: OCLiquidGlassGroup(
        settings: const OCLiquidGlassSettings(
          refractStrength: -0.08,
          blurRadiusPx: 1,
          specStrength: 2,
          specWidth: 0.5,
          specAngle: 145,
          specPower: 10,
          lightbandOffsetPx: 7,
          lightbandStrength: 0.5,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // isListening controls the glow. isVisible is intentionally used
            // only for the semantic "close" state of the button; completed
            // and failure states must not keep emitting visual light.
            IgnorePointer(
              child: Align(
                alignment: AlignmentGeometry.topCenter,
                // Keep the glow smaller than the 48x48 button surface so it
                // reads as a compact light mass instead of a square backdrop.
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedOpacity(
                      key: const ValueKey('workshop_voice_glow'),
                      opacity: state.isListening ? 1 : 0,
                      duration: glowDuration,
                      curve: Curves.easeInOut,
                      child: AnimatedBuilder(
                        animation: _glowController,
                        // Only this CustomPaint subtree is rebuilt on
                        // animation ticks; the Home page and Liquid Glass
                        // remain outside it.
                        builder: (context, child) => CustomPaint(
                          painter: _VoiceButtonGlowPainter(
                            // phase is the normalized position in the slow
                            // cycle.
                            phase: _glowController.value,
                            // amplitude gives the painter a small live
                            // response without changing the BLoC flow.
                            amplitude: state.amplitude,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The glow is deliberately behind OCLiquidGlass: the glass can
            // refract and blur the light instead of merely drawing over it.
            OCLiquidGlass(
              borderRadius: 37,
              color: colors.background.withValues(alpha: 0.30),
              child: InkWell(
                customBorder: shape,
                onTap: widget.onPressed,
                child: Center(
                  child: AnimatedScale(
                    scale: state.isListening ? 1.08 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: state.isListening
                        ? HugeIcon(
                            icon: HugeIcons.strokeRoundedMicOff01,
                            color: colors.textPrimary,
                            size: 28,
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedMic01,
                            color: colors.textPrimary,
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disegna la massa di luce che vive sotto il pulsante Liquid Glass.
///
/// [phase] arriva dall'[AnimationController] e rappresenta un ciclo
/// normalizzato da 0 a 1; il painter lo converte in sinusoidi lente per
/// ottenere un movimento fluido, non un'oscillazione da spinner.
/// [amplitude] è il livello audio normalizzato prodotto dal [VoiceSearchBloc]
/// e modifica appena raggio e luminosità del glow.
class _VoiceButtonGlowPainter extends CustomPainter {
  const _VoiceButtonGlowPainter({required this.phase, required this.amplitude});

  static const _cyan = Color(0xFF00F5FF);
  static const _electricBlue = Color(0xFF1479FF);
  static const _violet = Color(0xFF7C4DFF);

  final double phase;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final wave = math.sin(phase * math.pi * 2);
    final verticalWave = math.cos(phase * math.pi * 2);
    final normalizedAmplitude = amplitude.clamp(0.0, 1.0).toDouble();

    // Keep a faint minimum presence in short silences without creating a
    // bright hotspot; the voice can raise the softness and size gradually.
    final pulse = 0.34 + normalizedAmplitude * 0.66;
    final shortestSide = math.min(size.width, size.height);
    final radius = shortestSide * (0.90 + pulse * 0.28);
    final additivePaint = Paint()..blendMode = BlendMode.plus;

    // BlendMode.plus makes overlaps brighter, producing the soft neon core
    // that OCLiquidGlass will subsequently refract and blur.
    canvas.saveLayer(Offset.zero & size, Paint());
    _drawRadialGlow(
      canvas,
      additivePaint,
      center: Offset(
        size.width * (0.34 + wave * 0.10),
        size.height * (0.48 + verticalWave * 0.07),
      ),
      radius: radius,
      colors: [
        _cyan.withValues(alpha: 0.12 + pulse * 0.10),
        _cyan.withValues(alpha: 0.09 + pulse * 0.08),
        _electricBlue.withValues(alpha: 0.06 + pulse * 0.06),
        Colors.transparent,
      ],
      // Wide stops spread the light instead of forming a concentrated core.
      stops: const [0, 0.28, 0.68, 1],
    );
    _drawRadialGlow(
      canvas,
      additivePaint,
      center: Offset(
        size.width * (0.68 - wave * 0.11),
        size.height * (0.52 - verticalWave * 0.08),
      ),
      radius: radius * 0.92,
      colors: [
        _electricBlue.withValues(alpha: 0.11 + pulse * 0.09),
        _violet.withValues(alpha: 0.07 + pulse * 0.07),
        Colors.transparent,
      ],
      stops: const [0.08, 0.55, 1],
    );
    canvas.restore();
  }

  void _drawRadialGlow(
    Canvas canvas,
    Paint paint, {
    required Offset center,
    required double radius,
    required List<Color> colors,
    required List<double> stops,
  }) {
    paint.shader = RadialGradient(
      colors: colors,
      stops: stops,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_VoiceButtonGlowPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.amplitude != amplitude;
}
