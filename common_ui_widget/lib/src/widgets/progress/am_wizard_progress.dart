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
    final dotSize = widget.compact ? 11.0 : 12.0;
    final barBoxHeight = widget.compact ? 24.0 : 26.0;
    final trackTop = widget.compact ? 9.0 : 10.0;
    const trackHeight = 6.0;

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
                                    top: trackTop,
                                    left: inset,
                                    width: trackWidth,
                                    height: trackHeight,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: CustomPaint(
                                        painter: _ProgressPainter(
                                          progress: animatedPercent,
                                          phase:
                                              _controller.value * math.pi * 2,
                                          color: widget.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (var index = 0; index < count; index++)
                                    Positioned(
                                      left:
                                          inset +
                                          trackWidth *
                                              _stepFraction(index, count) -
                                          dotSize / 2,
                                      top:
                                          trackTop +
                                          (trackHeight - dotSize) / 2,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        width: dotSize,
                                        height: dotSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: index <= clampedStep
                                              ? widget.color
                                              : colors.surfaceRaised,
                                          border: Border.all(
                                            color: index <= clampedStep
                                                ? Colors.white.withValues(
                                                    alpha: 0.85,
                                                  )
                                                : colors.border,
                                            width: 1.5,
                                          ),
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
  const _ProgressPainter({
    required this.progress,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    final width = size.width * progress;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, size.height),
      Paint()..color = color,
    );
    if (width == 0) return;
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= width; x += 3) {
      path.lineTo(x, size.height * .5 + math.sin(x * .06 + phase) * 2);
    }
    path
      ..lineTo(width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .16));
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) =>
      old.progress != progress || old.phase != phase || old.color != color;
}
