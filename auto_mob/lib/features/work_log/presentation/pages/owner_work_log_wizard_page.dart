import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_bar/am_wizard_app_bar.dart';

class OwnerWorkLogWizardPage extends StatelessWidget {
  const OwnerWorkLogWizardPage({
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
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(AmWizardAppBar.height),
      child: SafeArea(
        bottom: false,
        child: AmWizardAppBar(
          title: 'AGGIUNGI LAVORO',
          backButtonKey: const Key('owner-work-log-wizard-back-frame'),
          onBackPressed: () => context.pop(false),
        ),
      ),
    ),
    body: WorkLogWizardBody(
      context: workLogContext,
      cubit: cubit,
      onSaved: (_) => context.pop(true),
    ),
  );
}
