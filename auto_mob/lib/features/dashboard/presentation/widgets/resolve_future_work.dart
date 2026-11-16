import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../future_work/domain/entities/future_work_summary.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

enum _ReportResolution { workPerformed, disappeared }

Future<void> resolveFutureWork(
  BuildContext context, {
  required FutureWorkSummary report,
  required Vehicle vehicle,
  required VoidCallback onDisappeared,
  required ValueChanged<WorkLogSaveResult> onWorkSaved,
}) async {
  final colors = AmThemeColors.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final choice = await showAmStatusDialog<_ReportResolution>(
    context,
    icon: HugeIcons.strokeRoundedAlert02,
    iconColor: colors.accent,
    title: 'Come hai risolto?',
    actionsAxis: Axis.vertical,
    width: 320,
    barrierDismissible: true,
    actions: [
      AmDialogAction(
        label: 'Ho eseguito il lavoro',
        color: colors.accent,
        filled: true,
        onPressed: () => navigator.pop(_ReportResolution.workPerformed),
      ),
      AmDialogAction(
        label: 'La spia / il problema è scomparso',
        color: colors.accent,
        onPressed: () => navigator.pop(_ReportResolution.disappeared),
      ),
      AmDialogAction(
        label: 'Annulla',
        color: colors.textSecondary,
        onPressed: () => navigator.pop(),
      ),
    ],
  );
  if (!context.mounted || choice == null) return;
  if (choice == _ReportResolution.disappeared) {
    onDisappeared();
    return;
  }

  final names = report.warningLights
      .map((light) => amWarningLightCatalog[light.code]?.$1 ?? 'Altra spia')
      .toSet();
  final saved = await context.pushNamed<WorkLogSaveResult>(
    'aggiungi_lavoro',
    extra: {
      'vehicleId': vehicle.id,
      'vehicleName': '${vehicle.brand} ${vehicle.model}',
      'currentKm': vehicle.kmCurrent,
      'initialWorkType': 'altro',
      'initialCustomName': names.isEmpty ? report.message : names.join(', '),
      'sourceReportId': report.recordId,
    },
  );
  if (saved != null && context.mounted) onWorkSaved(saved);
}
