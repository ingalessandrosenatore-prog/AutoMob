import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../future_work/domain/entities/future_work_summary.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

enum _ReportResolution { workPerformed, disappeared }

Future<void> resolveFutureWork(
  BuildContext context, {
  required FutureWorkSummary report,
  required Vehicle vehicle,
  required VoidCallback onDisappeared,
  required VoidCallback onWorkSaved,
}) async {
  final choice = await showDialog<_ReportResolution>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Come hai risolto?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.build_outlined),
            title: const Text('Ho eseguito il lavoro'),
            onTap: () =>
                Navigator.pop(dialogContext, _ReportResolution.workPerformed),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('La spia / il problema è scomparso'),
            onTap: () =>
                Navigator.pop(dialogContext, _ReportResolution.disappeared),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annulla'),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == _ReportResolution.disappeared) {
    onDisappeared();
    return;
  }

  final names = report.warningLights
      .map((light) => amWarningLightCatalog[light.code]?.$1 ?? 'Altra spia')
      .toSet();
  final saved = await context.pushNamed<bool>(
    'aggiungi_lavoro',
    extra: {
      'vehicleId': vehicle.id,
      'vehicleName': '${vehicle.brand} ${vehicle.model}',
      'currentKm': vehicle.kmCurrent,
      'initialWorkType': 'altro',
      'initialCustomName': names.isEmpty ? report.message : names.join(', '),
      'initialNotes': report.message,
      'sourceReportId': report.recordId,
    },
  );
  // The wizard only returns success after the atomic save-and-resolve RPC.
  if (saved == true && context.mounted) onWorkSaved();
}
