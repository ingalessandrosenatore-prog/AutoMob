import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../../vehicle/domain/entities/maintenance_kpi.dart';
import '../../../vehicle/domain/entities/vehicle_maintenance_setting.dart';

Color? componentMaintenanceWarning(BuildContext context, MaintenanceKpi kpi) {
  final rows = kpi.components
      .map((component) => component.alertPercentage)
      .whereType<double>();
  if (rows.any((percent) => percent == 0)) {
    return Theme.of(context).colorScheme.error;
  }
  if (rows.any((percent) => percent < 20)) return const Color(0xffffaf37);
  return null;
}

class ComponentMaintenanceDetails extends StatelessWidget {
  const ComponentMaintenanceDetails({
    super.key,
    required this.kpi,
    required this.onRegister,
  });

  final MaintenanceKpi kpi;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AmThemeColors.of(context);
    final warning = componentMaintenanceWarning(context, kpi);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: colors.cardGradient,
            border: Border.all(color: warning ?? colors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kpi.group!.label, style: theme.textTheme.titleLarge),
                if (kpi.group == VehicleMaintenanceGroup.brakes)
                  Text(
                    'Ultimo controllo · ${kpi.lastInspectionDate == null ? '—' : MaterialLocalizations.of(context).formatCompactDate(kpi.lastInspectionDate!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 10),
                for (final component in kpi.components) ...[
                  _ComponentRow(component: component),
                  for (final part in component.parts)
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: _ComponentRow(component: part),
                    ),
                ],
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onRegister,
                  child: const Text('Registra intervento'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.component});

  final MaintenanceComponentKpi component;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final percent = component.percentage;
    final alertPercent = component.alertPercentage;
    final expired = alertPercent == 0;
    final dueSoon = alertPercent != null && alertPercent < 20;
    final indicator = expired
        ? Theme.of(context).colorScheme.error
        : dueSoon
        ? const Color(0xffffaf37)
        : colors.textPrimary;
    final date = component.dueDate;
    final dueText = date == null
        ? null
        : 'Scadenza a tempo · ${MaterialLocalizations.of(context).formatCompactDate(date)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: expired ? indicator.withValues(alpha: .11) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            percent == null
                ? Icons.remove
                : dueSoon
                ? Icons.warning_amber_rounded
                : Icons.check,
            size: 18,
            color: indicator,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(component.label),
                if (dueText != null)
                  Text(dueText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(switch (percent) {
            null => '—',
            > 0 && < 1 => '<1%',
            _ => '${percent.floor()}%',
          }),
        ],
      ),
    );
  }
}
