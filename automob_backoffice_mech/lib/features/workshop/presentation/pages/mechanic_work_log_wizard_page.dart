import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

class MechanicWorkLogWizardPage extends StatelessWidget {
  const MechanicWorkLogWizardPage({
    required this.workLogContext,
    required this.cubit,
    super.key,
  });

  final WorkLogLaunchContext workLogContext;
  final WorkLogEditorCubit cubit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AmThemeColors.of(context).background,
    resizeToAvoidBottomInset: false,
    body: SafeArea(
      top: true,
      bottom: false,
      child: WorkLogWizardBody(
        context: workLogContext,
        cubit: cubit,
        onSaved: (_) => Navigator.of(context).pop(true),
      ),
    ),
  );
}
