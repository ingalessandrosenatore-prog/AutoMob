import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    extendBodyBehindAppBar: true,
    resizeToAvoidBottomInset: false,
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(AmWizardAppBar.heightWithBottom),
      child: SafeArea(
        bottom: false,
        child: AmWizardAppBar(
          title: 'AGGIUNGI LAVORO',
          backButtonKey: const Key('owner-work-log-wizard-back-frame'),
          onBackPressed: () => context.pop(),
          bottom: BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
            bloc: cubit,
            buildWhen: (previous, current) => previous.step != current.step,
            builder: (context, state) =>
                WorkLogWizardProgressHeader(step: state.step),
          ),
        ),
      ),
    ),
    body: WorkLogWizardBody(
      showHeaderProgress: false,
      context: workLogContext,
      cubit: cubit,
      onSaved: (result) => context.pop(result),
    ),
  );
}
