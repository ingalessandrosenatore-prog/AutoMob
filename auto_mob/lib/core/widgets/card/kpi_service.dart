import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:common_ui_widget/common_ui_widget.dart'
    show AmRouteBlurTransition;

import '../../theme/am_theme_colors.dart';

const _kpiCardRadius = 30.0;
const _kpiCornerSmoothing = 0.8;

SmoothRectangleBorder _kpiShape({double radius = _kpiCardRadius}) =>
    SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: _kpiCornerSmoothing,
      ),
    );

class AmMaintenanceKpiCard extends StatelessWidget {
  final Widget Function(double size, Color color) iconBuilder;
  final Color color;
  final String label;
  final int remainingKm;
  final double percentage;
  final int offersCount;
  final int reviewCount;
  final VoidCallback? onTap;
  final Animation<double>? routeAnimation;

  const AmMaintenanceKpiCard({
    super.key,
    required this.iconBuilder,
    required this.color,
    required this.label,
    required this.remainingKm,
    required this.percentage,
    this.offersCount = 0,
    this.reviewCount = 0,
    this.onTap,
    this.routeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final isCritical = remainingKm <= 0;
    final formattedKm = remainingKm.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final kmLabel = remainingKm < 0 ? '-$formattedKm' : formattedKm;

    final card = Container(
      key: const Key('am-maintenance-kpi-surface'),
      padding: const EdgeInsets.all(1.5),
      decoration: ShapeDecoration(
        gradient: colors.cardBorderGradient,
        shape: _kpiShape(),
        shadows: colors.cardShadows,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: _kpiShape()),
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.surface),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -16,
                child: Transform.rotate(
                  angle: -0.2,
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surface.withValues(alpha: 0.26),
                        color.withValues(alpha: 0.72),
                      ],
                    ).createShader(bounds),
                    child: iconBuilder(76, colors.textPrimary),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              alignment: Alignment.center,
                              child: iconBuilder(22, color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label.toUpperCase(),
                                maxLines: 2,
                                style: TextStyle(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: SizedBox.square(
                            key: const Key('maintenance-kpi-percentage-ring'),
                            dimension: 58,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: CircularProgressIndicator(
                                    value: 1,
                                    strokeWidth: 8,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.light
                                        ? colors.background
                                        : colors.surfaceRaised,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Positioned.fill(
                                  child: CircularProgressIndicator(
                                    value: (percentage / 100).clamp(0, 1),
                                    strokeWidth: 8,
                                    color: color,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  '${percentage.round()}%',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                kmLabel,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: isCritical
                                      ? colors.danger
                                      : colors.textPrimary,
                                ),
                              ),
                              Text(
                                'KM rimasti',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return AmRouteBlurTransition(animation: routeAnimation, child: card);
  }
}
