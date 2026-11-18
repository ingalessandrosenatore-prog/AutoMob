import 'package:common_ui_widget/common_ui_widget.dart' show AmThemeColors;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../vehicle/domain/entities/maintenance_kpi.dart';
import '../component_maintenance_details.dart';
import 'vehicle_hero_callouts.dart';
import 'vehicle_hero_layout.dart';

class VehicleHeroCalloutCard extends StatelessWidget {
  const VehicleHeroCalloutCard({
    super.key,
    required this.callout,
    required this.scale,
    required this.accent,
    required this.onKpiTap,
  });

  static double height(VehicleHeroCallout card, double scale) =>
      11 + 35 * scale + card.kpi.components.length * 19 * scale;

  final VehicleHeroCallout callout;
  final double scale;
  final Color accent;
  final ValueChanged<MaintenanceKpi> onKpiTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final border =
        componentMaintenanceWarning(context, callout.kpi) ?? colors.border;
    return Material(
      color: colors.surfaceRaised.withValues(
        alpha: callout.slot == VehicleHeroSlot.belowBrakes ? .88 : .95,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _VehicleHeroCardContent(
        callout: callout,
        scale: scale,
        accent: accent,
        onKpiTap: onKpiTap,
      ),
    );
  }
}

class _VehicleHeroCardContent extends StatelessWidget {
  const _VehicleHeroCardContent({
    required this.callout,
    required this.scale,
    required this.accent,
    required this.onKpiTap,
  });

  final VehicleHeroCallout callout;
  final double scale;
  final Color accent;
  final ValueChanged<MaintenanceKpi> onKpiTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final kpi = callout.kpi;
    final hasParts = kpi.components.isNotEmpty;
    final hasKnownParts = kpi.components.any((part) => part.percentage != null);
    final summary = !hasParts
        ? '${_percent(kpi.percentage)} · ${kpi.remainingKm} km'
        : !hasKnownParts
        ? '—'
        : '${_percent(kpi.percentage)}${kpi.hasUnknownComponents ? ' · parziale' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onKpiTap(kpi),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 35 * scale,
                    child: Row(
                      children: [
                        HugeIcon(icon: callout.icon, size: 15, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                callout.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final row in kpi.components)
                    if (callout.rotation case final rotation?
                        when identical(row, kpi.components.last))
                      InkWell(
                        onTap: () => onKpiTap(rotation),
                        child: _VehicleHeroComponentRow(row: row, scale: scale),
                      )
                    else
                      _VehicleHeroComponentRow(row: row, scale: scale),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleHeroComponentRow extends StatelessWidget {
  const _VehicleHeroComponentRow({required this.row, required this.scale});

  final MaintenanceComponentKpi row;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final percent = row.percentage;
    final alert = row.alertPercentage;
    final warning = alert != null && alert < 20;
    final expired = alert == 0;
    final color = expired
        ? Theme.of(context).colorScheme.error
        : warning
        ? const Color(0xffffaf37)
        : colors.textPrimary;
    final textStyle = TextStyle(color: color, fontSize: 10);

    return Container(
      height: 19 * scale,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: expired ? color.withValues(alpha: .12) : null,
      ),
      child: Row(
        children: [
          Icon(
            percent == null
                ? Icons.remove
                : warning
                ? Icons.warning_amber_rounded
                : Icons.check,
            color: color,
            size: 11,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          const SizedBox(width: 3),
          Text(_percent(percent), style: textStyle),
        ],
      ),
    );
  }
}

String _percent(double? percent) => switch (percent) {
  null => '—',
  > 0 && < 1 => '<1%',
  _ => '${percent.floor()}%',
};
