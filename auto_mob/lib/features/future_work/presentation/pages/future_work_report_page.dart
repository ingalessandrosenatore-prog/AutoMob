import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/performance_flags.dart';
import '../../../../core/widgets/app_bar/am_wizard_app_bar.dart';
import '../bloc/future_work_report_cubit.dart';
import '../widgets/future_work_report_form.dart';

class FutureWorkReportPage extends StatefulWidget {
  const FutureWorkReportPage({
    required this.vehicleId,
    required this.vehicleName,
    required this.cubit,
    super.key,
  });

  final String vehicleId;
  final String vehicleName;
  final FutureWorkReportCubit cubit;

  @override
  State<FutureWorkReportPage> createState() => _FutureWorkReportPageState();
}

class _FutureWorkReportPageState extends State<FutureWorkReportPage> {
  final _descriptionController = TextEditingController();
  final _onboardController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _onboardController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocConsumer<FutureWorkReportCubit, FutureWorkReportState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == FutureWorkReportStatus.success) {
            context.pop(true);
          }
        },
        builder: (context, state) {
          final colors = AmThemeColors.of(context);
          final isSubmitting =
              state.status == FutureWorkReportStatus.submitting;
          final topInset = MediaQuery.paddingOf(context).top;
          return Scaffold(
            backgroundColor: colors.background,
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: false,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(AmWizardAppBar.height),
              child: SafeArea(
                bottom: false,
                child: AmWizardAppBar(
                  title: 'SEGNALA PROBLEMA',
                  backButtonKey: const Key('future-work-back'),
                  onBackPressed: () => context.pop(false),
                ),
              ),
            ),
            body: SmartEdge(
              blur: kHeavyEffects,
              fallbackTint: colors.background,
              edges: [
                EdgeBlur(
                  type: EdgeType.topEdge,
                  size: topInset + AmWizardAppBar.height + 20,
                  sigma: 10,
                  tintColor: colors.background,
                  controlPoints: [
                    ControlPoint(position: 0.8, type: ControlPointType.visible),
                    ControlPoint(
                      position: 1,
                      type: ControlPointType.transparent,
                    ),
                  ],
                ),
                EdgeBlur(
                  type: EdgeType.bottomEdge,
                  size: 24,
                  sigma: 10,
                  tintColor: colors.background,
                  controlPoints: [
                    ControlPoint(position: 0, type: ControlPointType.visible),
                    ControlPoint(
                      position: 1,
                      type: ControlPointType.transparent,
                    ),
                  ],
                ),
              ],
              child: SingleChildScrollView(
                key: const Key('future-work-form-scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  topInset + AmWizardAppBar.height + 16,
                  20,
                  28,
                ),
                child: FutureWorkReportForm(
                  vehicleName: widget.vehicleName,
                  descriptionController: _descriptionController,
                  onboardController: _onboardController,
                  dateController: _dateController,
                  state: state,
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              // Keep the action reachable while editing multiline fields.
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: SmallPrincipal(
                    key: const ValueKey('future-work-submit'),
                    label: 'SALVA SEGNALAZIONE',
                    color: colors.accent,
                    width: double.infinity,
                    height: 52,
                    fontSize: 16,
                    isLoading: isSubmitting,
                    onPressed: state.canSubmit
                        ? () {
                            FocusScope.of(context).unfocus();
                            context.read<FutureWorkReportCubit>().submit(
                              widget.vehicleId,
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
