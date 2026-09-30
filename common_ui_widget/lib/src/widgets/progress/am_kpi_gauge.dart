import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/am_theme_colors.dart';

/// Tachimetro presentazionale condiviso, configurabile con testo oppure icona.
class AmKpiGauge extends StatefulWidget {
  const AmKpiGauge({
    super.key,
    this.label,
    this.icon,
    this.semanticLabel,
    required this.value,
    this.maximum,
    this.progress,
    required this.valueFormatter,
    this.compact = false,
    this.headingFontSize,
    this.valueFontSize,
    this.maximumFontSize,
  }) : assert((label == null) != (icon == null)),
       assert(label != null || semanticLabel != null),
       assert(maximum != null || progress != null);

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final num? value;
  final num? maximum;

  /// Avanzamento esplicito usato quando il dato non possiede un massimo.
  final double? progress;
  final String Function(num value) valueFormatter;
  final bool compact;
  final double? headingFontSize;
  final double? valueFontSize;
  final double? maximumFontSize;

  @override
  State<AmKpiGauge> createState() => _AmKpiGaugeState();
}

class _AmKpiGaugeState extends State<AmKpiGauge>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 1600);

  late final AnimationController _controller;
  late double _beginValue;
  late double _endValue;
  late double _beginProgress;
  late double _endProgress;

  double get _animationProgress =>
      Curves.easeOutCubic.transform(_controller.value);

  double get _animatedValue =>
      _beginValue + (_endValue - _beginValue) * _animationProgress;

  double get _animatedProgress =>
      _beginProgress + (_endProgress - _beginProgress) * _animationProgress;

  double _targetProgress() {
    final explicitProgress = widget.progress;
    if (explicitProgress != null) {
      return explicitProgress.clamp(0, 1).toDouble();
    }
    final value = widget.value;
    final maximum = widget.maximum;
    if (value == null || maximum == null || maximum <= 0) return 0;
    return (value / maximum).clamp(0, 1).toDouble();
  }

  @override
  void initState() {
    super.initState();
    _beginValue = 0;
    _endValue = widget.value?.toDouble() ?? 0;
    _beginProgress = 0;
    _endProgress = _targetProgress();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AmKpiGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.maximum == widget.maximum &&
        oldWidget.progress == widget.progress) {
      return;
    }
    _beginValue = _animatedValue;
    _beginProgress = _animatedProgress;
    _endValue = widget.value?.toDouble() ?? 0;
    _endProgress = _targetProgress();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller
        ..duration = _animationDuration
        ..forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final targetProgress = _targetProgress();
    final percentage = (targetProgress * 100).round();
    final label = widget.semanticLabel ?? widget.label!;
    final formattedValue = widget.value == null
        ? '-'
        : widget.valueFormatter(widget.value!);
    final semanticValue = widget.maximum == null
        ? '$formattedValue, $percentage% del periodo'
        : '$formattedValue di '
              '${widget.valueFormatter(widget.maximum!)}, $percentage%';
    final height = widget.compact ? 108.0 : 142.0;
    final contentTop = widget.compact ? 52.0 : 75.0;
    final valueTop = widget.compact ? 68.0 : 89.0;
    return Semantics(
      container: true,
      label: label,
      value: semanticValue,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animatedValue = math.max(0.0, _animatedValue);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('am_kpi_outer_ring'),
                      painter: _AmKpiOuterRingPainter(
                        borderColor: colors.border,
                        compact: widget.compact,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('am_kpi_tick_ring'),
                      painter: _AmKpiTickRingPainter(
                        progress: _animatedProgress,
                        activeColor: colors.accent,
                        compact: widget.compact,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('am_kpi_dial'),
                      painter: _AmKpiGaugePainter(
                        progress: _animatedProgress,
                        activeColor: colors.accent,
                        needleColor: colors.textPrimary,
                        pivotColor: colors.accent,
                        compact: widget.compact,
                      ),
                    ),
                  ),
                  Positioned(
                    key: const ValueKey('am_kpi_heading'),
                    top: contentTop,
                    left: 6,
                    right: 6,
                    child: widget.icon != null
                        ? Icon(
                            widget.icon,
                            color: colors.accent,
                            size: widget.compact ? 13 : 16,
                          )
                        : Text(
                            widget.label!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: widget.headingFontSize ?? 7.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                  ),
                  Positioned(
                    key: const ValueKey('am_kpi_value'),
                    top: valueTop,
                    left: 4,
                    right: 4,
                    child: Text(
                      widget.value == null
                          ? '-'
                          : widget.valueFormatter(animatedValue.round()),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize:
                            widget.valueFontSize ?? (widget.compact ? 9 : 10.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (widget.maximum != null)
                    Positioned(
                      key: const ValueKey('am_kpi_maximum'),
                      right: 4,
                      bottom: widget.compact ? 4 : 7,
                      child: Text(
                        widget.valueFormatter(widget.maximum!),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize:
                              widget.maximumFontSize ??
                              (widget.compact ? 7 : 8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AmKpiGaugePainter extends CustomPainter {
  const _AmKpiGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.needleColor,
    required this.pivotColor,
    required this.compact,
  });

  final double progress;
  final Color activeColor;
  final Color needleColor;
  final Color pivotColor;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final (:center, :radius, :scale) = _gaugeGeometry(size, compact);
    final dial = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      dial,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = activeColor.withValues(alpha: 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      dial,
      math.pi,
      math.pi * progress,
      false,
      Paint()
        ..color = activeColor.withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14 * scale
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 9 * scale),
    );
    canvas.drawArc(
      dial,
      math.pi,
      math.pi * progress,
      false,
      Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * scale
        ..strokeCap = StrokeCap.round,
    );

    final needleAngle = math.pi + math.pi * progress;
    final needleTip = _point(center, radius - 20 * scale, needleAngle);
    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = activeColor.withValues(alpha: 0.28)
        ..strokeWidth = 8 * scale
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * scale),
    );
    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 6 * scale, Paint()..color = pivotColor);
    canvas.drawCircle(
      center.translate(-1.5 * scale, -1.5 * scale),
      1.7 * scale,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  Offset _point(Offset center, double radius, double angle) => Offset(
    center.dx + math.cos(angle) * radius,
    center.dy + math.sin(angle) * radius,
  );

  @override
  bool shouldRepaint(covariant _AmKpiGaugePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      activeColor != oldDelegate.activeColor ||
      needleColor != oldDelegate.needleColor ||
      pivotColor != oldDelegate.pivotColor ||
      compact != oldDelegate.compact;
}

class _AmKpiTickRingPainter extends CustomPainter {
  const _AmKpiTickRingPainter({
    required this.progress,
    required this.activeColor,
    required this.compact,
  });

  final double progress;
  final Color activeColor;
  final bool compact;

  static const _tickCount = 19;

  @override
  void paint(Canvas canvas, Size size) {
    final (:center, :radius, :scale) = _gaugeGeometry(size, compact);
    final safeProgress = progress.clamp(0.0, 1.0);
    for (var index = 0; index < _tickCount; index++) {
      final fraction = index / (_tickCount - 1);
      final angle = math.pi + math.pi * fraction;
      final isMajor = index % 3 == 0;
      final outerRadius = radius - 7 * scale;
      final innerRadius = outerRadius - (isMajor ? 7 : 4) * scale;
      final isActive = fraction <= safeProgress;
      canvas.drawLine(
        _pointOnGauge(center, innerRadius, angle),
        _pointOnGauge(center, outerRadius, angle),
        Paint()
          ..color = isActive
              ? activeColor.withValues(alpha: 0.82)
              : activeColor.withValues(alpha: 0.28)
          ..strokeWidth = (isMajor ? 1.05 : 0.7) * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmKpiTickRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      activeColor != oldDelegate.activeColor ||
      compact != oldDelegate.compact;
}

class _AmKpiOuterRingPainter extends CustomPainter {
  const _AmKpiOuterRingPainter({
    required this.borderColor,
    required this.compact,
  });

  final Color borderColor;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final (:center, :radius, :scale) = _gaugeGeometry(size, compact);
    final ring = Rect.fromCircle(center: center, radius: radius + 5 * scale);
    canvas.drawArc(
      ring,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = borderColor.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AmKpiOuterRingPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor || compact != oldDelegate.compact;
}

({Offset center, double radius, double scale}) _gaugeGeometry(
  Size size,
  bool compact,
) {
  final center = Offset(size.width / 2, size.height - (compact ? 22 : 29));
  return (
    center: center,
    radius: math.min(
      size.width * (compact ? 0.38 : 0.31),
      size.height * (compact ? 0.55 : 0.50),
    ),
    scale: compact ? 0.8 : 1.0,
  );
}

Offset _pointOnGauge(Offset center, double radius, double angle) => Offset(
  center.dx + math.cos(angle) * radius,
  center.dy + math.sin(angle) * radius,
);
