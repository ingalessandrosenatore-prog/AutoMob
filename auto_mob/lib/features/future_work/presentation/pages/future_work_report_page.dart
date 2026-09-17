import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/input/date_picker_field.dart';
import '../bloc/future_work_report_cubit.dart';

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
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
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
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              foregroundColor: colors.textPrimary,
              title: const Text('Segnala problema'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.vehicleName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Descrivi il lavoro da ricordare e indica entro quando va effettuato.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      key: const ValueKey('future-work-description'),
                      controller: _descriptionController,
                      enabled: !isSubmitting,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 1000,
                      onChanged: context
                          .read<FutureWorkReportCubit>()
                          .descriptionChanged,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Problema o lavoro futuro',
                        hintText: 'Es. Controllare le pastiglie posteriori',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        AmDatePickerField(
                          key: const ValueKey('future-work-reminder-date'),
                          label: 'Da effettuare entro',
                          placeholder: 'Seleziona una data',
                          controller: _dateController,
                          isRequired: true,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 10),
                          onDateSelected: context
                              .read<FutureWorkReportCubit>()
                              .reminderDateChanged,
                        ),
                      ],
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        state.error!,
                        key: const ValueKey('future-work-error'),
                        style: TextStyle(
                          color: colors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        key: const ValueKey('future-work-submit'),
                        onPressed: state.canSubmit
                            ? () => context
                                  .read<FutureWorkReportCubit>()
                                  .submit(widget.vehicleId)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.onMedia,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: colors.onMedia,
                                ),
                              )
                            : const Text(
                                'Salva segnalazione',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
