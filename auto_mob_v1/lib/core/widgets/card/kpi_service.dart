import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';

class AmMaintenanceKpiCard extends StatelessWidget {
  final Widget Function(double size, Color color) iconBuilder;
  final Color color;
  final String label;
  final int remainingKm;
  final double percentage;
  final int offersCount;
  final int reviewCount;
  final VoidCallback? onTap;

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
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCritical = remainingKm <= 0;
    final formattedKm = remainingKm.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    final kmLabel = remainingKm < 0 ? '-$formattedKm' : formattedKm;

    return Container(
      key: const Key('am-maintenance-kpi-surface'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [colors.surfaceHighlight, colors.surfaceDeep]
              : [colors.surfaceDeep, colors.surfaceHighlight],
        ),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colors.border,
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 55,
              child: Transform.rotate(
                angle: -0.2,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.textSecondary.withValues(alpha: 0.06),
                      color.withValues(alpha: 0.2),
                    ],
                  ).createShader(bounds),
                  child: iconBuilder(84, colors.textPrimary),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                iconBuilder(20, color),
                                const SizedBox(width: 10),
                                Text(
                                  label.toUpperCase(),
                                  style: TextStyle(
                                    color: colors.textPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$kmLabel ',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: isCritical
                                        ? colors.danger
                                        : colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'KM Rimasti',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SegmentedProgressBar(
                              percentage: percentage,
                              color: color,
                            ),
                          ],
                        ),
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: colors.textSecondary.withValues(alpha: 0.45),
                        size: 28,
                        strokeWidth: 3,
                      ),
                    ],
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

class _SegmentedProgressBar extends StatelessWidget {
  final double percentage;
  final Color color;

  const _SegmentedProgressBar({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final threshold = (index + 1) * 25;
        final isActive = percentage >= threshold - 12;

        return Expanded(
          child: Container(
            height: 10,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
