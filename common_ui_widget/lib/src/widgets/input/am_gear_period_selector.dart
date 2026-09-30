import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/am_theme_colors.dart';

/// Selettore controllato che traduce tre periodi in innesti meccanici.
class AmGearPeriodSelector extends StatelessWidget {
  const AmGearPeriodSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.semanticLabel = 'Periodo statistiche',
  }) : assert(labels.length == 3),
       assert(selectedIndex >= 0 && selectedIndex < 3);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var index = 0; index < labels.length; index++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == selectedIndex,
                    child: InkWell(
                      key: ValueKey('am_gear_period_$index'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AnimatedDefaultTextStyle(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            color: index == selectedIndex
                                ? colors.accent
                                : colors.textSecondary,
                            fontSize: 11,
                            fontWeight: index == selectedIndex
                                ? FontWeight.w800
                                : FontWeight.w600,
                            letterSpacing: 0.8,
                            shadows: index == selectedIndex
                                ? [
                                    Shadow(
                                      color: colors.accent.withValues(
                                        alpha: 0.7,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                          child: Text(labels[index].toUpperCase()),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 48,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: selectedIndex.toDouble()),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 440),
              curve: Curves.easeInOutCubic,
              builder: (context, selection, _) => CustomPaint(
                key: const ValueKey('am_gear_gate'),
                painter: _AmGearGatePainter(
                  selection: selection,
                  grooveColor: colors.surface,
                  edgeColor: colors.border,
                  highlightColor: colors.borderHighlight,
                  knobColor: colors.accent,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmGearGatePainter extends CustomPainter {
  const _AmGearGatePainter({
    required this.selection,
    required this.grooveColor,
    required this.edgeColor,
    required this.highlightColor,
    required this.knobColor,
  });

  final double selection;
  final Color grooveColor;
  final Color edgeColor;
  final Color highlightColor;
  final Color knobColor;

  static const _positions = [0.14, 0.5, 0.86];

  @override
  void paint(Canvas canvas, Size size) {
    const slotTop = 10.0;
    final channelY = size.height - 10;
    final xs = [for (final position in _positions) size.width * position];
    final gate = Path()..moveTo(xs.first, slotTop);
    for (var index = 0; index < xs.length; index++) {
      if (index > 0) gate.lineTo(xs[index], channelY);
      gate
        ..lineTo(xs[index], slotTop)
        ..lineTo(xs[index], channelY);
    }

    canvas.drawPath(
      gate,
      Paint()
        ..color = edgeColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      gate,
      Paint()
        ..color = grooveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      gate,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    final safeSelection = selection.clamp(0.0, 2.0);
    final leftIndex = safeSelection.floor();
    final rightIndex = math.min(leftIndex + 1, 2);
    final travel = safeSelection - leftIndex;
    final knobCenter = Offset(
      _lerp(xs[leftIndex], xs[rightIndex], travel),
      _lerp(slotTop, channelY, math.sin(math.pi * travel)),
    );
    canvas.drawCircle(
      knobCenter,
      7,
      Paint()
        ..color = knobColor.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      knobCenter,
      4.5,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: [knobColor.withValues(alpha: 0.8), knobColor],
        ).createShader(Rect.fromCircle(center: knobCenter, radius: 4.5)),
    );
    canvas.drawCircle(
      knobCenter.translate(-2, -2),
      1,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  double _lerp(double begin, double end, double t) => begin + (end - begin) * t;

  @override
  bool shouldRepaint(covariant _AmGearGatePainter oldDelegate) =>
      selection != oldDelegate.selection ||
      grooveColor != oldDelegate.grooveColor ||
      edgeColor != oldDelegate.edgeColor ||
      highlightColor != oldDelegate.highlightColor ||
      knobColor != oldDelegate.knobColor;
}
