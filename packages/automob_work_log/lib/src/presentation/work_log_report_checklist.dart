import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'work_log_editor_cubit.dart';
import 'work_log_report_notes.dart';

class WorkLogReportChecklist extends StatelessWidget {
  const WorkLogReportChecklist({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
        buildWhen: (previous, current) =>
            previous.openReports != current.openReports ||
            previous.selectedReportIds != current.selectedReportIds ||
            previous.loadingReports != current.loadingReports ||
            previous.reportsError != current.reportsError ||
            previous.isSaving != current.isSaving,
        builder: (context, state) =>
            _WorkLogReportChecklistContent(state: state),
      );
}

class _WorkLogReportChecklistContent extends StatelessWidget {
  const _WorkLogReportChecklistContent({required this.state});

  final WorkLogEditorState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkLogEditorCubit>();
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Segnalazioni risolte con questo lavoro',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (state.loadingReports)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
          if (state.reportsError case final message?) ...[
            Text(message, style: TextStyle(color: colors.textSecondary)),
            TextButton(
              onPressed: cubit.loadReports,
              child: const Text('Ricarica segnalazioni'),
            ),
          ],
          if (state.openReports.isEmpty &&
              state.reportsError == null &&
              !state.loadingReports)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Nessuna segnalazione aperta per questo veicolo',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          for (final (report, lights) in state.openReports.map(
            (report) => (report, workLogReportLights(report)),
          ))
            CheckboxListTile(
              key: ValueKey('work-log-report-${report.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: colors.accent,
              value: state.selectedReportIds.contains(report.id),
              onChanged: state.isSaving || state.loadingReports
                  ? null
                  : (value) => cubit.selectReport(report.id, value == true),
              title: Text(
                lights.isEmpty ? report.description : lights,
                style: TextStyle(color: colors.textPrimary),
              ),
              subtitle: lights.isEmpty || report.description.isEmpty
                  ? null
                  : Text(
                      report.description,
                      style: TextStyle(color: colors.textSecondary),
                    ),
            ),
        ],
      ),
    );
  }
}
