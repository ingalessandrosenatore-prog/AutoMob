import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../../../../core/config/performance_flags.dart';
import '../../../../core/widgets/buttons/am_choice_chip.dart';
import '../../../../core/widgets/input/date_picker_field.dart';
import '../../../../core/widgets/smart/smart_edge.dart';
import '../../domain/entities/revision_interval.dart';
import '../bloc/revision_update_cubit.dart';
import 'registration/step_info_banner.dart';

class RevisionUpdatePopUp<T> extends Page<T> {
  final String vehicleId;
  final DateTime? currentRevisionDate;
  final RevisionUpdateCubit Function() createCubit;

  const RevisionUpdatePopUp({
    super.key,
    required this.vehicleId,
    required this.currentRevisionDate,
    required this.createCubit,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
      ),
      builder: (context) => BlocProvider<RevisionUpdateCubit>(
        create: (_) => createCubit(),
        child: _RevisionUpdateContent(
          vehicleId: vehicleId,
          currentRevisionDate: currentRevisionDate,
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _RevisionUpdateContent extends StatefulWidget {
  final String vehicleId;
  final DateTime? currentRevisionDate;

  const _RevisionUpdateContent({
    required this.vehicleId,
    required this.currentRevisionDate,
  });

  @override
  State<_RevisionUpdateContent> createState() => _RevisionUpdateContentState();
}

class _RevisionUpdateContentState extends State<_RevisionUpdateContent> {
  final _dateController = TextEditingController();

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isValid(DateTime? date) => date != null && !date.isBefore(_today);

  @override
  void initState() {
    super.initState();
    final current = widget.currentRevisionDate;
    if (current != null) {
      _dateController.text = _formatDate(current);
    }
    context.read<RevisionUpdateCubit>().initialize(current);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _selectInterval(RevisionInterval interval) {
    context.read<RevisionUpdateCubit>().selectInterval(
      interval: interval,
      from: _today,
    );
  }

  void _selectManualDate(DateTime date) {
    context.read<RevisionUpdateCubit>().selectManualDate(date);
  }

  void _save() {
    context.read<RevisionUpdateCubit>().aggiorna(vehicleId: widget.vehicleId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);

    return BlocConsumer<RevisionUpdateCubit, RevisionUpdateState>(
      listener: (context, state) {
        final selectedDate = state.selectedDate;
        if (selectedDate != null) {
          _dateController.text = _formatDate(selectedDate);
        }
        if (state.status == RevisionUpdateStatus.success) {
          showAmStatusDialog<void>(
            context,
            icon: HugeIcons.strokeRoundedCheckmarkBadge01,
            iconColor: const Color(0xFF30D158),
            title: 'Revisione aggiornata',
            message: state.savedDate == null
                ? 'La nuova scadenza e stata salvata.'
                : 'Nuova scadenza: ${_formatDate(state.savedDate!)}',
            actions: [
              AmDialogAction(
                label: 'Chiudi',
                color: colors.accent,
                filled: true,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        } else if (state.status == RevisionUpdateStatus.failure) {
          showAmStatusDialog<void>(
            context,
            icon: HugeIcons.strokeRoundedAlert01,
            iconColor: colors.danger,
            title: 'Aggiornamento non riuscito',
            message: state.error ?? 'Errore durante l\'aggiornamento.',
            actions: [
              AmDialogAction(
                label: 'Chiudi',
                color: colors.info,
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
              ),
              AmDialogAction(
                label: 'Riprova',
                color: colors.accent,
                filled: true,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _save();
                },
              ),
            ],
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == RevisionUpdateStatus.loading;
        final enabled = _isValid(state.selectedDate) && !loading;
        final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
        final mediaSize = MediaQuery.sizeOf(context);
        final topSafeArea = MediaQuery.paddingOf(context).top;
        final maxModalHeight =
            (mediaSize.height - keyboardHeight - topSafeArea - 12)
                .clamp(0.0, mediaSize.height)
                .toDouble();

        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxModalHeight),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(50),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border(top: BorderSide(color: colors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RevisionHeader(
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 30),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar01,
                        color: colors.accent,
                        size: 52,
                        strokeWidth: 2.2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Quando scade la prossima revisione?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.currentRevisionDate == null
                            ? 'Scadenza attuale non impostata'
                            : 'Scadenza attuale: '
                                  '${_formatDate(widget.currentRevisionDate!)}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _RevisionIntervalPicker(
                        selected: state.selectedInterval,
                        onSelected: _selectInterval,
                      ),
                      const SizedBox(height: 24),
                      StepInfoBanner(
                        color: colors.info,
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        text:
                            'Se la data calcolata non e corretta, aggiornala manualmente.',
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          AmDatePickerField(
                            label: 'Prossima revisione',
                            placeholder: 'gg/mm/aaaa',
                            controller: _dateController,
                            isRequired: true,
                            firstDate: _today,
                            lastDate: DateTime(_today.year + 10),
                            onDateSelected: _selectManualDate,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: enabled ? _save : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(
                              alpha: enabled ? 1 : 0.32,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: loading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: colors.onMedia,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Salva revisione',
                                  style: TextStyle(
                                    color: enabled
                                        ? colors.onMedia
                                        : colors.textSecondary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RevisionHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _RevisionHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Aggiorna revisione',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.info.withValues(alpha: 0.35)),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: colors.info,
              size: 20,
              strokeWidth: 2.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _RevisionIntervalPicker extends StatelessWidget {
  final RevisionInterval? selected;
  final ValueChanged<RevisionInterval> onSelected;

  const _RevisionIntervalPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return SmartEdge(
      blur: kHeavyEffects,
      fallbackTint: colors.background,
      opacity: 0.74,
      edges: [
        EdgeBlur(
          type: EdgeType.leftEdge,
          size: 18,
          sigma: 6,
          tintColor: colors.background,
          controlPoints: [
            ControlPoint(position: 0.35, type: ControlPointType.visible),
            ControlPoint(position: 1, type: ControlPointType.transparent),
          ],
        ),
        EdgeBlur(
          type: EdgeType.rightEdge,
          size: 18,
          sigma: 6,
          tintColor: colors.background,
          controlPoints: [
            ControlPoint(position: 0.35, type: ControlPointType.visible),
            ControlPoint(position: 1, type: ControlPointType.transparent),
          ],
        ),
      ],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          spacing: 10,
          children: [
            for (final interval in RevisionInterval.values)
              AmChoiceChip(
                id: interval.index,
                label: _labelFor(interval),
                isSelected: selected == interval,
                activeColor: colors.accent,
                onTap: () => onSelected(interval),
              ),
          ],
        ),
      ),
    );
  }
}

String _labelFor(RevisionInterval interval) => switch (interval) {
  RevisionInterval.sixMonths => '6 mesi',
  RevisionInterval.oneYear => '1 anno',
  RevisionInterval.twoYears => '2 anni',
  RevisionInterval.fourYears => '4 anni',
};

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
