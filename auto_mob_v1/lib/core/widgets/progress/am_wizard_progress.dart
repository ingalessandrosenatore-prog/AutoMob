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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final count = widget.steps.length;
    final percent = count <= 1 ? 1.0 : widget.currentStep / (count - 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 34,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 380),
                curve: Curves.linear,
                tween: Tween<double>(end: percent),
                builder: (context, animatedPercent, child) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final slot = constraints.maxWidth / count;
                          final inset = slot / 2 - 13;
                          final trackWidth = constraints.maxWidth - inset * 2;
                          final x =
                              slot / 2 +
                              (constraints.maxWidth - slot) * animatedPercent;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 16,
                                left: inset,
                                width: trackWidth,
                                height: 10,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: CustomPaint(
                                    painter: _ProgressPainter(
                                      progress: animatedPercent,
                                      phase: _controller.value * math.pi * 2,
                                      color: widget.color,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: x - 20,
                                top: math.sin(_controller.value * math.pi * 8),
                                child: SvgPicture.asset(
                                  widget.indicatorAsset,
                                  width: 41,
                                  height: 41,
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
            const SizedBox(height: 14),
            Row(
              children: List.generate(count, (index) {
                final current = index == widget.currentStep;
                final done = index < widget.currentStep;
                return Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 26,
                        height: 26,
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
                    icon: HugeIcons.strokeRoundedValidationApproval,
                                size: 14,
                                color: colors.onMedia,
                                strokeWidth: 2.2,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.steps[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: current
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 12,
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
