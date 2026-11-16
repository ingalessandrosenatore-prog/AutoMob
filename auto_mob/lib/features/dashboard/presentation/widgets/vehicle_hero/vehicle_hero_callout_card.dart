import 'package:common_ui_widget/common_ui_widget.dart' show AmThemeColors;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../vehicle/domain/entities/maintenance_kpi.dart';

class VehicleHeroCalloutCard extends StatelessWidget {
  const VehicleHeroCalloutCard({
    super.key,
    required this.title,
    required this.icon,
    required this.kpi,
    required this.onKpiTap,
    this.secondary,
  });

  final String title;
  final List<List<dynamic>> icon;
  final MaintenanceKpi kpi;
  final MaintenanceKpi? secondary;
  final ValueChanged<MaintenanceKpi> onKpiTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(17)),
      side: BorderSide(color: colors.border),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: colors.cardGradient,
        shadows: colors.cardShadows,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onKpiTap(kpi),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Row(
                  children: [
                    HugeIcon(icon: icon, size: 19, color: colors.accent),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _KpiText(title: title, kpi: kpi),
                    ),
                  ],
                ),
              ),
            ),
            if (secondary case final rotation?)
              InkWell(
                onTap: () => onKpiTap(rotation),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 4, 9, 6),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: _KpiText(title: 'Inversione', kpi: rotation),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KpiText extends StatelessWidget {
  const _KpiText({required this.title, required this.kpi});

  final String title;
  final MaintenanceKpi kpi;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final km = kpi.remainingKm.toString().replaceAllMapped(
      RegExp(r'\d(?=(\d{3})+$)'),
      (m) => '${m[0]}.',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        Text(
          '${kpi.percentage.round()}% · $km km',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }
}
