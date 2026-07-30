import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';

const String _wheelAsset = 'lib/assets/icons/car_red.svg';
const double _stepDotDiameter = 26;

/// Barra di avanzamento "Registrazione veicolo" del wizard: percentuale +
/// barra (rettangolo di progresso con sinusoide interna e auto che vibra
/// "al minimo" sul suo angolo bottom-right) + pallini con etichetta per
/// ogni step. Parametrica (steps/currentStep/activeColor) cosi' e' riusabile
/// su tutte le pagine del flusso senza hardcodare il numero di step.
class RegistrationStepProgress extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final Color activeColor;

  const RegistrationStepProgress({
    super.key,
    required this.steps,
    required this.currentStep,
    this.activeColor = const Color(0xFFE85A1A),
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final percent = steps.length <= 1 ? 1.0 : currentStep / (steps.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            _ProgressTrack(
              percent: percent,
              activeColor: activeColor,
              stepsCount: steps.length,
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(steps.length, (index) {
                return Expanded(
                  child: _StepDot(
                    label: steps[index],
                    done: index < currentStep,
                    current: index == currentStep,
                    activeColor: activeColor,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra a 4 strati:
/// 1) sfondo arancione chiarissimo su tutta la barra;
/// 2) rettangolo arancione pieno (il progresso vero, bordi netti);
/// 3) una sinusoide disegnata SOLO dentro quel rettangolo (clip), con
///    origine nell'angolo bottom-right = posizione dell'auto;
/// 4) l'auto, che vibra "al minimo" proprio in quell'angolo (non rimbalza).
///
/// La barra e' allineata orizzontalmente con la riga dei pallini sotto:
/// inizia al centro del primo pallino e finisce al centro dell'ultimo
/// (non ai bordi del contenitore), esattamente come i pallini stessi
/// (ognuno al centro del proprio "slot" da `Expanded`).
class _ProgressTrack extends StatefulWidget {
  final double percent;
  final Color activeColor;
  final int stepsCount;

  const _ProgressTrack({
    required this.percent,
    required this.activeColor,
    required this.stepsCount,
  });

  @override
  State<_ProgressTrack> createState() => _ProgressTrackState();
}

class _ProgressTrackState extends State<_ProgressTrack>
    with TickerProviderStateMixin {
  // Due controller INDIPENDENTI invece di uno solo moltiplicato: prima la
  // vibrazione era `fase_onda * 8`, cioe' un multiplo derivato da un
  // controller lento (1600ms) → il motion pareva a "raffiche" (tu tu tu ...
  // pausa ... tu tu tu) invece che un ticchettio fisso. Un controller
  // dedicato, breve e lineare, che ripete SOLO se stesso, da' un'oscillazione
  // costante senza alcuna dipendenza da un'altra fase piu' lenta.
  late final AnimationController _waveController;
  late final AnimationController _vibrateController;

  // Altezza normale di una barra di progresso (non piu' un blocco alto);
  // la ruota e' piu' grande della barra e vi si appoggia sopra, un po'
  // sporgente, come nei riferimenti.
  static const double _height = 10;
  static const double _wheelSizeCar = 41;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    // Periodo fisso e breve: un ciclo di vibrazione ogni 160ms, sempre
    // uguale, per un ticchettio "tu tu tu tu tu" regolare e infinito.
    _vibrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _vibrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.percent.clamp(0.0, 1.0);
    return SizedBox(
      width: double.infinity,
      height: _height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _vibrateController]),
        builder: (context, _) {
          final wavePhase = _waveController.value * 2 * math.pi;
          final vibratePhase = _vibrateController.value * 2 * math.pi;
          return LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final slot = totalWidth / widget.stepsCount;
              // Bordi della barra allineati con l'ESTREMITA' esterna dei
              // cerchi step (non col loro centro): l'inset e' quindi il
              // centro del primo/ultimo slot meno il raggio del cerchio.
              final inset = slot / 2 - _stepDotDiameter / 2;
              final trackWidth = totalWidth - inset * 2;
              final wheelX = inset + trackWidth * percent;
              // Vibrazione da motore al minimo: solo bounce verticale + una
              // rotazione leggera in fase, niente asse X (la diagonale
              // creava un effetto "orbita" che sembrava a scatti).
              final vibrateY = math.sin(vibratePhase) * 1.1;
              final vibrateAngle = math.sin(vibratePhase) * 0.02;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: inset,
                    top: 0,
                    width: trackWidth,
                    height: _height,
                    child: RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_height / 2),
                        child: CustomPaint(
                          painter: _BarPainter(
                            percent: percent,
                            phase: wavePhase,
                            color: widget.activeColor,
                          ),
                          size: Size(trackWidth, _height),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: wheelX - _wheelSizeCar / 2,
                    top: _height / 3.5 - _wheelSizeCar / 2 + vibrateY,
                    child: Transform.rotate(
                      angle: vibrateAngle,
                      child: RepaintBoundary(
                        child: SvgPicture.asset(
                          _wheelAsset,
                          width: _wheelSizeCar,
                          height: _wheelSizeCar,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final double percent;
  final double phase;
  final Color color;

  _BarPainter({
    required this.percent,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1) Sfondo: arancione chiarissimo su tutta la barra.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color.lerp(color, Colors.white, 0.85)!,
    );

    final wheelX = size.width * percent;
    if (wheelX <= 0) return;

    // 2) Rettangolo di progresso: arancione pieno, bordi netti (non ondulato).
    final progressRect = Rect.fromLTWH(0, 0, wheelX, size.height);
    canvas.drawRect(progressRect, Paint()..color = color);

    // 3) Sinusoide disegnata solo dentro il rettangolo di progresso (clip),
    // con origine (fase zero) nell'angolo bottom-right = posizione della
    // ruota. Riempita (non solo tracciata): tutta l'area SOTTO la curva,
    // fino al fondo della barra, in bianco chiaro trasparente.
    canvas.save();
    canvas.clipRect(progressRect);
    final amplitude = size.height * 0.28;
    const frequency = 0.045;
    final baseline = size.height * 0.5;

    final wavePath = Path()..moveTo(0, size.height);
    const step = 4.0;
    var x = 0.0;
    while (x < wheelX) {
      final y =
          baseline + math.sin((x - wheelX) * frequency + phase) * amplitude;
      wavePath.lineTo(x, y);
      x += step;
    }
    final yAtWheel = baseline + math.sin(0 + phase) * amplitude;
    wavePath
      ..lineTo(wheelX, yAtWheel)
      ..lineTo(wheelX, size.height)
      ..close();

    canvas.drawPath(
      wavePath,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.percent != percent;
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final Color activeColor;

  const _StepDot({
    required this.label,
    required this.done,
    required this.current,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final bool highlighted = done || current;
    final Color borderColor = highlighted
        ? activeColor
        : colors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _stepDotDiameter,
          height: _stepDotDiameter,
          decoration: BoxDecoration(
            color: done ? activeColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: done
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedValidationApproval,
              color: colors.background,
              size: 14,
              strokeWidth: 2.2,
            )
                : current
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: current ? colors.textPrimary : colors.textSecondary,
            fontSize: 12,
            fontWeight: current ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
