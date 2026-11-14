import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/am_theme_colors.dart';

/// Indicatore animato riutilizzabile per wizard full-screen.
class AmWizardProgress extends StatefulWidget {
  final List<String> steps;
  final int currentStep;
  final Color color;
  final String? indicatorAsset;
  final bool compact;

  const AmWizardProgress({
    super.key,
    required this.steps,
    required this.currentStep,
    this.indicatorAsset,
    this.color = const Color(0xFFE85A1A),
    this.compact = false,
  });

  @override
  State<AmWizardProgress> createState() => _AmWizardProgressState();
}

class _AmWizardProgressState extends State<AmWizardProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _stepFraction(int index, int count) {
    if (count <= 1) return 1.0;
    if (index <= 0) return 0.18;
    if (index >= count - 1) return 0.94;
    return 0.18 + (0.94 - 0.18) * (index / (count - 1));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final count = widget.steps.length;
    final int clampedStep = widget.currentStep.clamp(0, math.max(0, count - 1));
    final carFraction = _stepFraction(clampedStep, count);
    final barPercent = count <= 1 || clampedStep >= count - 1
        ? 1.0
        : carFraction;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final outerPadding = widget.compact
        ? EdgeInsets.zero
        : const EdgeInsets.fromLTRB(20, 4, 20, 2);
    final innerPadding = widget.compact
        ? const EdgeInsets.symmetric(vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    final dotRadius = widget.compact ? 7.0 : 7.5;
    final barBoxHeight = widget.compact ? 24.0 : 26.0;
    const trackHeight = 6.0;
    final paintHeight = dotRadius * 2;
    final paintTop = (barBoxHeight - paintHeight) / 2;
    final stepFractions = List<double>.generate(
      count,
      (index) => _stepFraction(index, count),
      growable: false,
    );

    return Semantics(
      container: true,
      label:
          'Passaggio ${clampedStep + 1} di $count: '
          '${widget.steps[clampedStep]}',
      child: ExcludeSemantics(
        child: Padding(
          padding: outerPadding,
          child: Container(
            key: const Key('am-wizard-progress-surface'),
            padding: innerPadding,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: barBoxHeight,
                  child: TweenAnimationBuilder<double>(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(end: barPercent),
                    builder: (context, animatedPercent, child) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final slot = constraints.maxWidth / count;
                              final inset = widget.compact ? 0.0 : slot / 2;
                              final trackWidth = widget.compact
                                  ? constraints.maxWidth
                                  : constraints.maxWidth - slot;
                              final carSize = widget.compact ? 24.0 : 28.0;
                              final carTarget =
                                  inset +
                                  trackWidth *
                                      (clampedStep >= count - 1
                                          ? carFraction * animatedPercent
                                          : animatedPercent);
                              final clampedX = carTarget.clamp(
                                carSize / 2,
                                math.max(
                                  carSize / 2,
                                  constraints.maxWidth - carSize / 2,
                                ),
                              );
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: paintTop,
                                    left: inset,
                                    width: trackWidth,
                                    height: paintHeight,
                                    child: CustomPaint(
                                      painter: _ProgressPainter(
                                        progress: animatedPercent,
                                        phase: _controller.value * math.pi * 2,
                                        color: widget.color,
                                        trackHeight: trackHeight,
                                        dotRadius: dotRadius,
                                        stepFractions: stepFractions,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: clampedX - carSize / 2,
                                    top: reduceMotion
                                        ? 0
                                        : math.sin(
                                            _controller.value * math.pi * 8,
                                          ),
                                    child: widget.indicatorAsset == null
                                        ? Icon(
                                            Icons.build_circle_outlined,
                                            size: carSize,
                                            color: widget.color,
                                          )
                                        : SvgPicture.asset(
                                            widget.indicatorAsset!,
                                            width: carSize,
                                            height: carSize,
                                          ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                if (!widget.compact) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(count, (index) {
                      final current = index == clampedStep;
                      return Expanded(
                        child: Text(
                          widget.steps[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: current
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 11,
                            fontWeight: current
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color color;
  final double trackHeight;
  final double dotRadius;
  final List<double> stepFractions;

  const _ProgressPainter({
    required this.progress,
    required this.phase,
    required this.color,
    required this.trackHeight,
    required this.dotRadius,
    required this.stepFractions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final trackRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, cy - trackHeight / 2, size.width, trackHeight),
      Radius.circular(trackHeight / 2),
    );
    var combinedPath = Path()..addRRect(trackRRect);
    for (final fraction in stepFractions) {
      final dotPath = Path()
        ..addOval(
          Rect.fromCircle(
            center: Offset(size.width * fraction, cy),
            radius: dotRadius,
          ),
        );
      combinedPath = Path.combine(PathOperation.union, combinedPath, dotPath);
    }

    canvas.save();
    canvas.clipPath(combinedPath);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    final width = progress <= 0
        ? 0.0
        : (size.width * progress + dotRadius).clamp(0.0, size.width);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, size.height),
      Paint()..color = color,
    );
    if (width > 0) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= width; x += 3) {
        path.lineTo(x, cy + math.sin(x * .06 + phase) * 2);
      }
      path
        ..lineTo(width, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: .16),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) =>
      old.progress != progress ||
      old.phase != phase ||
      old.color != color ||
      old.trackHeight != trackHeight ||
      old.dotRadius != dotRadius;
}
