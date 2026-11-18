import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:common_ui_widget/performance_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_launch_context.dart';
import '../domain/work_log_type.dart';
import '../domain/work_log_parts_catalog.dart';
import 'work_log_editor_cubit.dart';
import 'work_log_notes_input.dart';
import 'work_log_report_checklist.dart';
import 'work_log_parts_picker.dart';
import 'work_log_spare_part_card.dart';
import 'work_log_type_selection_grid.dart';

const _orange = Color(0xFFFF6B00);
const workLogWizardSteps = ['Dati', 'Ricambi', 'Costi'];

/// Barra di avanzamento compatta per l'AppBar o l'header del wizard WorkLog.
class WorkLogWizardProgressHeader extends StatelessWidget {
  const WorkLogWizardProgressHeader({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) => AmWizardProgress(
    steps: workLogWizardSteps,
    currentStep: step,
    color: _orange,
    compact: true,
    indicatorAsset: 'packages/automob_work_log/assets/icons/car_red.svg',
  );
}

/// Il wizard originale AutoMob adattato al Cubit condiviso.
/// Le app possiedono soltanto app bar, route e callback di chiusura.
class WorkLogWizardBody extends StatefulWidget {
  const WorkLogWizardBody({
    required this.context,
    required this.cubit,
    required this.onSaved,
    this.showHeaderProgress = true,
    super.key,
  });

  final WorkLogLaunchContext context;
  final WorkLogEditorCubit cubit;
  final ValueChanged<WorkLogSaveResult> onSaved;
  final bool showHeaderProgress;

  @override
  State<WorkLogWizardBody> createState() => _WorkLogWizardBodyState();
}

class _WorkLogWizardBodyState extends State<WorkLogWizardBody> {
  late final PageController _pages;
  late final TextEditingController _km;
  final _customName = TextEditingController();
  final _notes = WorkLogNotesInput();
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    _km = TextEditingController(text: widget.context.currentKm.toString());
    _customName.text = widget.context.initialCustomName;
    widget.cubit.initialize(widget.context);
    _notes.showNotes(
      widget.cubit.state.notes,
      widget.cubit.state.resolvedProblemsNotes,
    );
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
          previous.message != current.message ||
          previous.notes != current.notes ||
          previous.openReports != current.openReports ||
          previous.selectedReportIds != current.selectedReportIds,
      listener: _onStateChanged,
      builder: (context, state) {
        final keyboardOverlap = math.max(
          0.0,
          MediaQuery.viewInsetsOf(context).bottom - _BottomBar.extent(context),
        );
        final colors = AmThemeColors.of(context);
        final mediaTop = MediaQuery.paddingOf(context).top;
        final topPadding = mediaTop + (widget.showHeaderProgress ? 36.0 : 0.0);
        return SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: SmartEdge(
                  blur: kHeavyEffects,
                  opacity: 0.96,
                  fallbackTint: colors.background,
                  edges: [
                    EdgeBlur(
                      type: EdgeType.topEdge,
                      size: topPadding > 0 ? topPadding + 12 : 84,
                      tintColor: colors.background,
                      sigma: 10,
                      controlPoints: [
                        ControlPoint(
                          position: 0.5,
                          type: ControlPointType.visible,
                        ),
                        ControlPoint(
                          position: 1,
                          type: ControlPointType.transparent,
                        ),
                      ],
                    ),
                    EdgeBlur(
                      type: EdgeType.bottomEdge,
                      size: _BottomBar.extent(context) + 16,
                      tintColor: colors.background,
                      sigma: 10,
                      controlPoints: [
                        ControlPoint(
                          position: 0.5,
                          type: ControlPointType.visible,
                        ),
                        ControlPoint(
                          position: 1,
                          type: ControlPointType.transparent,
                        ),
                      ],
                    ),
                  ],
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
                          topPadding: topPadding,
                        ),
                        _PartsStep(topPadding: topPadding),
                        _CostsStep(topPadding: topPadding),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.showHeaderProgress)
                Positioned(
                  top: mediaTop + 4,
                  left: 20,
                  right: 20,
                  child: WorkLogWizardProgressHeader(step: state.step),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomBar(
                  step: state.step,
                  isLoading: state.isSaving,
                  onBack: state.step == 0 || state.isSaving
                      ? null
                      : widget.cubit.previousStep,
                  onNext: state.isSaving || (state.step == 2 && !state.canSave)
                      ? () {}
                      : state.step == 2
                      ? widget.cubit.submit
                      : widget.cubit.nextStep,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  void _onStateChanged(BuildContext context, WorkLogEditorState state) {
    _notes.showNotes(state.notes, state.resolvedProblemsNotes);
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
    required this.topPadding,
  });

  final TextEditingController km;
  final TextEditingController customName;
  final WorkLogNotesInput notes;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return ListView(
      key: const PageStorageKey('work-log-data-step'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 120),
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
          builder: (context, state) => WorkLogTypeSelectionGrid(
            selectedType: state.type,
            onChanged: context.read<WorkLogEditorCubit>().changeType,
          ),
        ),
        BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
          buildWhen: (previous, current) => previous.type != current.type,
          builder: (context, state) =>
              WorkLogType.tryFromWire(state.type)?.allowsCustomName != true
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
        const WorkLogReportChecklist(),
        _Field(
          key: const Key('work-log-notes'),
          label: 'NOTE',
          controller: notes,
          maxLines: 4,
          inputFormatters: [notes.formatter],
          onChanged: (_) =>
              context.read<WorkLogEditorCubit>().changeNotes(notes.manualNotes),
        ),
      ],
    );
  }
}

class _PartsStep extends StatelessWidget {
  const _PartsStep({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
        buildWhen: (previous, current) =>
            previous.partsData != current.partsData ||
            previous.loadingParts != current.loadingParts ||
            previous.partsError != current.partsError ||
            previous.parts != current.parts ||
            previous.partsQuery != current.partsQuery ||
            previous.partsCategory != current.partsCategory,
        builder: (context, state) {
          if (state.loadingParts) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.partsError case final message?) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  TextButton(
                    onPressed: context.read<WorkLogEditorCubit>().loadParts,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            );
          }
          return WorkLogPartsPicker(
            topPadding: topPadding,
            selectedParts: state.parts,
            query: state.partsQuery,
            selectedCategory: state.partsCategory,
            catalog: state.partsData?.catalog ?? kWorkLogPartsCatalog,
            onQueryChanged: context.read<WorkLogEditorCubit>().changePartsQuery,
            onCategoryChanged: context
                .read<WorkLogEditorCubit>()
                .changePartsCategory,
            onPartToggled: context.read<WorkLogEditorCubit>().togglePart,
          );
        },
      );
}

class _CostsStep extends StatelessWidget {
  const _CostsStep({required this.topPadding});

  final double topPadding;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<WorkLogEditorCubit, WorkLogEditorState>(
    buildWhen: (previous, current) =>
        previous.parts != current.parts ||
        previous.partsData != current.partsData,
    builder: (context, state) => Stack(
      children: [
        Positioned.fill(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, topPadding + 76, 24, 120),
            children: [
              if (state.parts.isEmpty)
                Text(
                  'Nessun ricambio selezionato',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AmThemeColors.of(context).textSecondary,
                  ),
                ),
              for (final item in state.parts)
                WorkLogSparePartCard(
                  item: item,
                  name:
                      state.partsData?.catalog[item.partId]?.name ??
                      kPartsCatalog[item.partId] ??
                      'Ricambio',
                  onRemove: () => context.read<WorkLogEditorCubit>().removePart(
                    item.partId,
                  ),
                  onItemChanged: context.read<WorkLogEditorCubit>().updatePart,
                ),
            ],
          ),
        ),
        Positioned(
          top: topPadding + 12,
          left: 24,
          right: 24,
          child: _TotalBar(total: state.partsTotal),
        ),
      ],
    ),
  );
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
      math.max(14.0, MediaQuery.viewPaddingOf(context).bottom + 6);
  static double extent(BuildContext context) =>
      10 + 34 + _bottomPadding(context);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final showBack = onBack != null;
    final label = step == 2 ? 'Completa' : 'Continua';
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, _bottomPadding(context)),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: showBack ? 34 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showBack ? 1 : 0,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: AmIconButton(
                    width: 34,
                    height: 34,
                    radius: 17,
                    showShadow: true,
                    shadowColor: Colors.white.withValues(alpha: 0.08),
                    shadowBlurRadius: 8,
                    shadowSpreadRadius: 0,
                    shadowOffset: const Offset(0, 2),
                    backgroundColor: colors.surface,
                    borderColor: Colors.white.withValues(alpha: 0.22),
                    borderWidth: 0.8,
                    iconColor: colors.accent,
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    iconTurns: 0.5,
                    iconSize: 20,
                    strokeWidth: 2.2,
                    tooltip: 'Indietro',
                    onPressed: onBack ?? () {},
                  ),
                ),
              ),
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: AmMainFab(
                key: const Key('work-log-next'),
                label: label,
                height: 34,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                color: colors.accent,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                trailingIcon: HugeIcons.strokeRoundedArrowRight01,
                iconSize: 15,
                isLoading: isLoading,
                onPressed: isLoading ? () {} : onNext,
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
    this.inputFormatters,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? suffix;
  final String? error;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

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
          inputFormatters: inputFormatters,
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
