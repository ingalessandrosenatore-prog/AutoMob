import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/input/date_picker_field.dart';
import '../bloc/future_work_report_cubit.dart';
import 'warning_light_selector.dart';

class FutureWorkReportForm extends StatelessWidget {
  const FutureWorkReportForm({
    required this.vehicleName,
    required this.descriptionController,
    required this.onboardController,
    required this.dateController,
    required this.state,
    super.key,
  });

  final String vehicleName;
  final TextEditingController descriptionController;
  final TextEditingController onboardController;
  final TextEditingController dateController;
  final FutureWorkReportState state;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final cubit = context.read<FutureWorkReportCubit>();
    final enabled = state.status != FutureWorkReportStatus.submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          vehicleName,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Aggiungi le spie che hai visto, il messaggio del computer di bordo o ciò che hai notato.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        const WarningLightSelector(),
        const SizedBox(height: 24),
        Row(
          children: [
            AmTextField(
              key: const ValueKey('future-work-onboard-message'),
              label: 'Messaggio del computer di bordo',
              placeholder: 'Facoltativo · Riporta il testo mostrato dall’auto',
              controller: onboardController,
              isRequired: false,
              obscureText: false,
              keyboardType: TextInputType.multiline,
              enabled: enabled,
              maxLength: 1000,
              height: 112,
              onChanged: (value) =>
                  cubit.onboardMessageChanged(value as String),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            AmTextField(
              key: const ValueKey('future-work-description'),
              label: 'Anomalia che hai notato',
              placeholder: 'Facoltativo · Es. Sento un rumore quando freno',
              controller: descriptionController,
              isRequired: false,
              obscureText: false,
              keyboardType: TextInputType.multiline,
              enabled: enabled,
              maxLength: 1000,
              height: 144,
              onChanged: (value) => cubit.descriptionChanged(value as String),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AbsorbPointer(
          absorbing: !enabled,
          child: Row(
            children: [
              AmDatePickerField(
                key: const ValueKey('future-work-reminder-date'),
                label: 'Da effettuare entro',
                placeholder: 'Seleziona una data',
                controller: dateController,
                isRequired: true,
                firstDate: DateTime.now(),
                lastDate: DateTime(DateTime.now().year + 10),
                onDateSelected: cubit.reminderDateChanged,
              ),
            ],
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 14),
          Text(
            state.error!,
            key: const ValueKey('future-work-error'),
            style: TextStyle(color: colors.danger, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
