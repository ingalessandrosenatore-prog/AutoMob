import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_launch_context.dart';
import '../domain/work_log_parts_catalog.dart';
import 'work_log_editor_cubit.dart';
import 'work_log_parts_picker.dart';
import 'work_log_spare_part_card.dart';

const _orange = Color(0xFFFF6B00);
const _steps = ['Dati', 'Ricambi', 'Costi'];

/// Il wizard originale AutoMob adattato al Cubit condiviso.
/// Le app possiedono soltanto app bar, route e callback di chiusura.
class WorkLogWizardBody extends StatefulWidget {
  const WorkLogWizardBody({
    required this.context,
    required this.cubit,
    required this.onSaved,
    super.key,
  });

  final WorkLogLaunchContext context;
  final WorkLogEditorCubit cubit;
  final ValueChanged<WorkLogSaveResult> onSaved;

  @override
  State<WorkLogWizardBody> createState() => _WorkLogWizardBodyState();
}

class _WorkLogWizardBodyState extends State<WorkLogWizardBody> {
  late final PageController _pages;
  late final TextEditingController _km;
  final _customName = TextEditingController();
  final _notes = TextEditingController();
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    _km = TextEditingController(text: widget.context.currentKm.toString());
    widget.cubit.initialize(widget.context);
    FocusManager.instance.addListener(_keepFocusedFieldVisible);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepFocusedFieldVisible);
    _pages.dispose();
    _km.dispose();
    _customName.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _keepFocusedFieldVisible() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !focusedContext.mounted) return;
      Scrollable.ensureVisible(
        focusedContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.35,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.cubit,
    child: BlocConsumer<WorkLogEditorCubit, WorkLogEditorState>(
      listenWhen: (previous, current) =>
          previous.step != current.step ||
          previous.status != current.status ||
          previous.message != current.message,
      listener: _onStateChanged,
      builder: (context, state) {
        final keyboardOverlap = math.max(
          0.0,
          MediaQuery.viewInsetsOf(context).bottom - _BottomBar.extent(context),
        );
        return SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              AmWizardProgress(
                steps: _steps,
                currentStep: state.step,
                color: _orange,
                indicatorAsset:
                    'packages/automob_work_log/assets/icons/car_red.svg',
              ),
              Expanded(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(bottom: keyboardOverlap),
                  child: PageView(
                    controller: _pages,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DataStep(
                        km: _km,
                        customName: _customName,
                        notes: _notes,
                      ),
                      const _PartsStep(),
                      const _CostsStep(),
                    ],
                  ),
                ),
              ),
              _BottomBar(
                step: state.step,
                isLoading: state.isSaving,
                onBack: state.step == 0 || state.isSaving
                    ? null
                    : widget.cubit.previousStep,
                onNext: state.isSaving
                    ? () {}
                    : state.step == 2
                    ? widget.cubit.submit
                    : widget.cubit.nextStep,
              ),
            ],
          ),
        );
      },
    ),
  );

  void _onStateChanged(BuildContext context, WorkLogEditorState state) {
    if (_pages.hasClients && _pages.page?.round() != state.step) {
      _pages.animateToPage(
        state.step,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
    if (_dialogVisible) return;
    if (state.status == WorkLogEditorStatus.failure && state.message != null) {
      _dialogVisible = true;
      showAmStatusDialog<void>(
        context,
        icon: HugeIcons.strokeRoundedAlert01,
        iconColor: const Color(0xFFFF453A),
        title: 'Non è stato possibile inserire il valore',
        message: state.message!,
        actions: [
          AmDialogAction(
            label: 'Chiudi',
            color: const Color(0xFF0A84FF),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _dialogVisible = false;
              widget.cubit.resumeEditing();
            },
          ),
          AmDialogAction(
            label: 'Riprova',
            color: _orange,
            filled: true,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _dialogVisible = false;
              widget.cubit.resumeEditing();
            },
          ),
        ],
      );
    } else if (state.status == WorkLogEditorStatus.success &&
        state.result != null) {
      _dialogVisible = true;
      showAmStatusDialog<void>(
        context,
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        iconColor: const Color(0xFF30D158),
        title: 'Lavoro registrato',
        message: 'Hai registrato correttamente il lavoro.',
        actions: [
          AmDialogAction(
            label: 'Chiudi',
            color: const Color(0xFF0A84FF),
            filled: true,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _dialogVisible = false;
              widget.onSaved(state.result!);
            },
          ),
        ],
      );
    }
  }
}

class _DataStep extends StatelessWidget {
  const _DataStep({
    required this.km,
    required this.customName,
    required this.notes,
  });

  final TextEditingController km;
  final TextEditingController customName;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return AmEdgeBlur(
      child: ListView(
        key: const PageStorageKey('work-log-data-step'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.info.withValues(alpha: .2)),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  color: colors.info,
                  strokeWidth: 2.2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Inserisci i dati principali dell’intervento.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
            buildWhen: (previous, current) =>
                previous.serviceKm != current.serviceKm ||
                previous.minimumKm != current.minimumKm,
            builder: (context, state) => _Field(
              key: const Key('work-log-km-field'),
              label: 'CHILOMETRI ATTUALI',
              controller: km,
              keyboardType: TextInputType.number,
              suffix: 'km',
              error: state.serviceKm < state.minimumKm
                  ? 'Inserisci almeno ${state.minimumKm} km.'
                  : null,
              onChanged: context.read<WorkLogEditorCubit>().changeKm,
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
            buildWhen: (previous, current) => previous.type != current.type,
            builder: (context, state) => _WorkTypeChipGrid(
              selectedType: state.type,
              onChanged: context.read<WorkLogEditorCubit>().changeType,
            ),
          ),
          BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
            buildWhen: (previous, current) => previous.type != current.type,
            builder: (context, state) => state.type != 'altro'
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _Field(
                      key: const Key('work-log-custom-name'),
                      label: 'NOME INTERVENTO',
                      controller: customName,
                      onChanged: context
                          .read<WorkLogEditorCubit>()
                          .changeCustomName,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          _Field(
            key: const Key('work-log-notes'),
            label: 'NOTE',
            controller: notes,
            maxLines: 4,
            onChanged: context.read<WorkLogEditorCubit>().changeNotes,
          ),
        ],
      ),
    );
  }
}

class _PartsStep extends StatelessWidget {
  const _PartsStep();

  @override
  Widget build(BuildContext context) => AmEdgeBlur(
    child: BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
      buildWhen: (previous, current) =>
          previous.parts != current.parts ||
          previous.partsQuery != current.partsQuery,
      builder: (context, state) => WorkLogPartsPicker(
        selectedParts: state.parts,
        query: state.partsQuery,
        onQueryChanged: context.read<WorkLogEditorCubit>().changePartsQuery,
        onPartToggled: context.read<WorkLogEditorCubit>().togglePart,
      ),
    ),
  );
}

class _CostsStep extends StatelessWidget {
  const _CostsStep();

  @override
  Widget build(BuildContext context) => AmEdgeBlur(
    child: BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
      buildWhen: (previous, current) => previous.parts != current.parts,
      builder: (context, state) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: _TotalBar(total: state.partsTotal),
          ),
          Expanded(
            child: state.parts.isEmpty
                ? Center(
                    child: Text(
                      'Nessun ricambio selezionato',
                      style: TextStyle(
                        color: AmThemeColors.of(context).textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
                    itemCount: state.parts.length,
                    itemBuilder: (_, index) {
                      final item = state.parts[index];
                      return WorkLogSparePartCard(
                        item: item,
                        name: kPartsCatalog[item.partId] ?? 'Ricambio',
                        onRemove: () => context
                            .read<WorkLogEditorCubit>()
                            .removePart(item.partId),
                        onItemChanged: context
                            .read<WorkLogEditorCubit>()
                            .updatePart,
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

class _WorkTypeChipGrid extends StatelessWidget {
  const _WorkTypeChipGrid({
    required this.selectedType,
    required this.onChanged,
  });
  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELEZIONA TIPO INTERVENTO:',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final type in _workTypes)
              _WorkTypeChip(
                type: type,
                selected: selectedType == type.value,
                onTap: () => onChanged(type.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorkTypeChip extends StatelessWidget {
  const _WorkTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });
  final _WorkType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final background = selected ? colors.accent : colors.surface;
    final foreground = selected ? colors.onMedia : colors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.accent
                  : colors.surfaceHighlight.withValues(alpha: .55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.onMedia.withValues(alpha: .16)
                      : colors.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: type.icon,
                  size: 18,
                  color: foreground,
                  strokeWidth: 2.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedReceiptCent,
            color: colors.textPrimary,
            strokeWidth: 2.2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'TOTALE RICAMBI',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            'EUR ${total.toStringAsFixed(2)}',
            key: const Key('work-log-total'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });
  final int step;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  static double _bottomPadding(BuildContext context) =>
      math.max(20.0, MediaQuery.viewPaddingOf(context).bottom + 8);
  static double extent(BuildContext context) =>
      20 + 52 + _bottomPadding(context);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final showBack = onBack != null;
    final label = step == 2 ? 'COMPLETA' : 'CONTINUA';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, _bottomPadding(context)),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: showBack ? 52 : 0,
              margin: EdgeInsets.only(right: showBack ? 16 : 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showBack ? 1 : 0,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: AmIconButton(
                    width: 52,
                    height: 52,
                    radius: 26,
                    showShadow: true,
                    shadowColor: colors.shadow.withValues(alpha: 0.18),
                    shadowBlurRadius: 8,
                    shadowOffset: const Offset(0, 3),
                    backgroundColor: colors.surface,
                    iconColor: colors.accent,
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    iconTurns: 0.5,
                    iconSize: 28,
                    strokeWidth: 2.2,
                    tooltip: 'Indietro',
                    onPressed: onBack ?? () {},
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: AmMainFab(
                  key: const Key('work-log-next'),
                  label: label,
                  height: 52,
                  width: double.infinity,
                  color: colors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : onNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.suffix,
    this.error,
    this.maxLines = 1,
    this.onChanged,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? suffix;
  final String? error;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, isRequired: label != 'NOTE'),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: _decoration(
            context,
            multiline: maxLines > 1,
          ).copyWith(suffixText: suffix, errorText: error),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.isRequired = false});
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
        children: [
          TextSpan(text: label.toUpperCase()),
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(color: colors.info),
            ),
        ],
      ),
    );
  }
}

InputDecoration _decoration(BuildContext context, {bool multiline = false}) {
  final colors = AmThemeColors.of(context);
  return InputDecoration(
    filled: true,
    fillColor: colors.surface,
    constraints: multiline ? null : const BoxConstraints(minHeight: 52),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.accent),
    ),
  );
}

typedef _WorkType = ({String value, String label, List<List<dynamic>> icon});

final _workTypes = <_WorkType>[
  (value: 'tagliando', label: 'Tagliando', icon: HugeIcons.strokeRoundedTools),
  (
    value: 'distribuzione',
    label: 'Distribuzione',
    icon: HugeIcons.strokeRoundedSettings02,
  ),
  (
    value: 'pneumatici_cambio',
    label: 'Cambio gomme',
    icon: HugeIcons.strokeRoundedTire,
  ),
  (
    value: 'revisione',
    label: 'Revisione',
    icon: HugeIcons.strokeRoundedValidation,
  ),
  (
    value: 'pneumatici_inversione',
    label: 'Inversione gomme',
    icon: HugeIcons.strokeRoundedRefresh,
  ),
  (
    value: 'altro',
    label: 'Altro',
    icon: HugeIcons.strokeRoundedMoreHorizontalCircle02,
  ),
];
