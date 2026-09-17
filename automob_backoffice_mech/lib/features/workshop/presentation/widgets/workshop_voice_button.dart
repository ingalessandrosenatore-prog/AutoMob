import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../bloc/voice_search_state.dart';
import 'workshop_voice_glow_painter.dart';

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
    this.gradient,
  });

  final VoiceSearchState state;
  final VoidCallback onPressed;
  final Gradient? gradient;

  @override
  State<WorkshopVoiceButton> createState() => _WorkshopVoiceButtonState();
}

class _WorkshopVoiceButtonState extends State<WorkshopVoiceButton>
    with SingleTickerProviderStateMixin {
  /// Controller lento e ciclico: i suoi tick vengono consumati soltanto dal
  /// [AnimatedBuilder] del [CustomPaint], non dall'albero della Home.
  late final AnimationController _glowController;
  late final AmLiquidGlassRepaintController _glassRepaint;
  bool? _disableAnimations;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _glassRepaint = AmLiquidGlassRepaintController();
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
    _glassRepaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
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
        repaint: _glassRepaint,
        settings: const OCLiquidGlassSettings(
          refractStrength: -0.08,
          blurRadiusPx: 1,
          specStrength: 2,
          specWidth: 1,
          specAngle: 145,
          specPower: 10,
          lightbandOffsetPx: 0,
          lightbandStrength: 0,
        ),
        child: Stack(
          key: const ValueKey('workshop_voice_stack'),
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // isListening controls the glow. isVisible is intentionally used
            // only for the semantic "close" state of the button; completed
            // and failure states must not keep emitting visual light.
            IgnorePointer(
              child: ClipOval(
                child: AnimatedOpacity(
                  key: const ValueKey('workshop_voice_glow'),
                  opacity: state.isListening ? 1 : 0,
                  duration: glowDuration,
                  curve: Curves.easeInOut,
                  child: AnimatedBuilder(
                    animation: _glowController,
                    // Only this CustomPaint subtree is rebuilt on animation
                    // ticks; the Home page and Liquid Glass remain outside it.
                    builder: (context, child) => CustomPaint(
                      key: const ValueKey('workshop_voice_glow_paint'),
                      painter: WorkshopVoiceGlowPainter(
                        color: colors.info,
                        phase: _glowController.value,
                        amplitude: state.amplitude,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The glow is deliberately behind OCLiquidGlass: the glass can
            // refract and blur the light instead of merely drawing over it.
            AmSoftButton(
              liquidGlassEnabled: true,
              width: 68,
              height: 68,
              iconSize: 28,
              iconWeight: 2.2,
              iconColor: colors.textPrimary,
              icon: state.isListening
                  ? HugeIcons.strokeRoundedMicOff01
                  : HugeIcons.strokeRoundedMic01,
              iSgradient: widget.gradient != null,
              gradient: widget.gradient,
              liquidGlassRepaint: _glassRepaint,
              onPressed: widget.onPressed,
              shadow: true,
              boxShadow: const BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                spreadRadius: 0.1,
                offset: Offset(0, 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
