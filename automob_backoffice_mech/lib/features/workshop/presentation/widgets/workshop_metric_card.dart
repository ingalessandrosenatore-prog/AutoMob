import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import 'workshop_metric_trend.dart';

class WorkshopMetricCard extends StatelessWidget {
  const WorkshopMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.trend,
    this.trendIsPercentage = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final num? trend;
  final bool trendIsPercentage;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: colors.cardBorderGradient,
        boxShadow: colors.cardShadows,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: colors.cardGradient,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, color: colors.accent, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (trend != null)
                    WorkshopMetricTrend(
                      value: trend!,
                      isPercentage: trendIsPercentage,
                    ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
