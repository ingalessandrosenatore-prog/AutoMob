import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';

/// Indicatore animato riutilizzabile per wizard full-screen.
class AmWizardProgress extends StatefulWidget {
  final List<String> steps;
  final int currentStep;
  final Color color;
  final String indicatorAsset;

  const AmWizardProgress({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.indicatorAsset,
    this.color = const Color(0xFFE85A1A),
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

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final count = widget.steps.length;
    final percent = count <= 1 ? 1.0 : widget.currentStep / (count - 1);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label:
          'Passaggio ${widget.currentStep + 1} di $count: '
          '${widget.steps[widget.currentStep]}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                  child: TweenAnimationBuilder<double>(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.linear,
                    tween: Tween<double>(end: percent),
                    builder: (context, animatedPercent, child) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final slot = constraints.maxWidth / count;
                              final inset = slot / 2;
                              final trackWidth = constraints.maxWidth - slot;
                              final x =
                                  slot / 2 +
                                  (constraints.maxWidth - slot) *
                                      animatedPercent;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: 12,
                                    left: inset,
                                    width: trackWidth,
                                    height: 6,
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
                                  Positioned(
                                    left: x - 16,
                                    top: reduceMotion
                                        ? -1
                                        : math.sin(
                                            _controller.value * math.pi * 8,
                                          ),
                                    child: SvgPicture.asset(
                                      widget.indicatorAsset,
                                      width: 32,
                                      height: 32,
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
                const SizedBox(height: 8),
                Row(
                  children: List.generate(count, (index) {
                    final current = index == widget.currentStep;
                    final done = index < widget.currentStep;
                    return Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done ? widget.color : Colors.transparent,
                              border: Border.all(
                                color: current || done
                                    ? widget.color
                                    : colors.surfaceRaised,
                                width: 2,
                              ),
                            ),
                            child: done
                                ? HugeIcon(
                                    // La versione 1.1.7 non espone
                                    // `strokeRoundedCheck`: `strokeRoundedValidation`
                                    // e' la spunta semplice equivalente.
                                    icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                    size: 12,
                                    color: colors.onMedia,
                                    strokeWidth:1.5,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.steps[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: current
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontSize: 11,
                              fontWeight: current
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
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
