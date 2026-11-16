import 'package:common_ui_widget/common_ui_widget.dart'
    show amWarningLightCatalog;

import '../domain/work_log_report.dart';

String workLogReportLights(WorkLogReport report) {
  final labels = {
    for (final code in report.warningLightCodes)
      amWarningLightCatalog[code]?.$1 ?? 'Altra spia',
  };
  return labels.join(', ');
}

String composeResolvedProblemsNotes(Iterable<WorkLogReport> reports) {
  final buffer = StringBuffer();
  var separator = 'Problemi risolti: ';
  for (final report in reports) {
    final lights = workLogReportLights(report);
    final description = report.description.trim();
    buffer.write(separator);
    if (lights.isNotEmpty) {
      buffer
        ..write('Spia spenta: ')
        ..write(lights);
      if (description.isNotEmpty) buffer.write(' - ');
    }
    buffer.write(
      lights.isEmpty && description.isEmpty ? 'Segnalazione' : description,
    );
    separator = '\n';
  }
  return buffer.toString();
}

String appendResolvedProblemsNotes(String manual, String problems) {
  if (manual.isEmpty) return problems;
  if (problems.isEmpty) return manual;
  return '$manual\n$problems';
}
