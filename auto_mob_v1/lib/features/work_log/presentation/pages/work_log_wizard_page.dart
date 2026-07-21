import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import '../../../../core/config/performance_flags.dart';
import '../../../../core/constants/parts_catalog.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/am_theme_colors.dart';
import '../../../../core/types/enum_pop_up.dart';
import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/am_icon_button.dart';
import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/buttons/soft_button.dart';
import '../../../../core/widgets/card/am_spare_part_card.dart';
import '../../../../core/widgets/dialog/am_status_dialog.dart';
import '../../../../core/widgets/progress/am_wizard_progress.dart';
import '../bloc/work_log_bloc.dart';
import '../bloc/work_log_event.dart';
import '../bloc/work_log_state.dart';

const _orange = Color(0xFFFF6B00);
const _steps = ['Dati', 'Ricambi', 'Costi'];

/// Wizard UI per l'inserimento di un lavoro. Il salvataggio remoto verra'
/// collegato in un passaggio successivo: qui il BLoC conserva il draft.
class WorkLogWizardPage extends StatelessWidget {
  final String vehicleId;
  final int currentKm;
  final EnumPopUp initialWorkType;

  const WorkLogWizardPage({
    super.key,
    required this.vehicleId,
    required this.currentKm,
    required this.initialWorkType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocProvider(
      create: (_) {
        final bloc = sl<WorkLogBloc>(
          param1: vehicleId,
          param2: initialWorkType,
        );
        bloc.add(InitKm(vehicleKm: currentKm));
        return bloc;
      },
      child: PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: colors.background,
          // La tastiera non deve spostare la bottom bar: l'inset viene
          // applicato esclusivamente al PageView nel body del wizard.
          resizeToAvoidBottomInset: false,
          body: _WorkLogWizardBody(currentKm: currentKm),
        ),
      ),
    );
  }
}

class _WorkLogWizardBody extends StatefulWidget {
  final int currentKm;

  const _WorkLogWizardBody({required this.currentKm});

  @override
  State<_WorkLogWizardBody> createState() => _WorkLogWizardBodyState();
}

class _WorkLogWizardBodyState extends State<_WorkLogWizardBody> {
  late final PageController _pages;
  late final TextEditingController _km;
  final _customName = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkLogBloc>().state;
    _pages = PageController(initialPage: state.currentStep);
    _km = TextEditingController(text: widget.currentKm.toString());
  }

  @override
  void dispose() {
    _pages.dispose();
    _km.dispose();
    _customName.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool _validateData(WorkLogState state) {
    final km = int.tryParse(_km.text.trim());
    if (km == null || km < state.vehicleKm) {
      context.read<WorkLogBloc>().add(WorkLogValidationRequested());
      return false;
    }
    if (state.type == EnumPopUp.altro && _customName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Specifica il tipo di intervento')),
      );
      return false;
    }
    return true;
  }

  void _next(WorkLogState state) {
    if (state.currentStep == 0 && !_validateData(state)) return;
    if (state.currentStep == 2) {
      if (state.status != WorkLogStatus.loading) {
        context.read<WorkLogBloc>().add(OnSubmitEvent());
      }
      return;
    }
    context.read<WorkLogBloc>().add(
      WorkLogWizardStepChanged(state.currentStep + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocConsumer<WorkLogBloc, WorkLogState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep ||
          previous.status != current.status,
      listener: _onStateChanged,
      builder: (context, state) {
        final keyboardOverlap = math.max(
          0.0,
          MediaQuery.viewInsetsOf(context).bottom - _BottomBar.extent(context),
        );
        final addButton = AmSoftButton(
          width: 48,
          height: 48,
          color: _orange,
          icon: HugeIcons.strokeRoundedAdd01,
          iconTurns: 0.125,
          onPressed: state.status == WorkLogStatus.loading
              ? () {}
              : () => Navigator.of(context).pop(),
        );
        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 48, height: 48),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'AGGIUNGI LAVORO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: const [
                                Shadow(
                                  color: Colors.black12,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: kHeavyEffects
                            ? OCLiquidGlassGroup(
                                settings: const OCLiquidGlassSettings(
                                  refractStrength: -0.130,
                                  blurRadiusPx: 1.0,
                                  specStrength: 0,
                                  specWidth: 0,
                                  specAngle: 145,
                                  blendPx: 20,
                                  specPower: 10,
                                ),
                                child: addButton,
                              )
                            : addButton,
                      ),
                    ),
                  ],
                ),
              ),
              AmWizardProgress(
                steps: _steps,
                currentStep: state.currentStep,
                color: _orange,
                indicatorAsset: 'lib/assets/icons/car_red.svg',
              ),
              Expanded(
                child: Padding(
                  // La barra resta fissa in basso (dietro la tastiera),
                  // mentre solo il viewport degli step perde lo spazio
                  // effettivamente intersecato dalla tastiera.
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
                step: state.currentStep,
                isLoading: state.status == WorkLogStatus.loading,
                onBack:
                    state.currentStep == 0 ||
                        state.status == WorkLogStatus.loading
                    ? null
                    : () => context.read<WorkLogBloc>().add(
                        WorkLogWizardStepChanged(state.currentStep - 1),
                      ),
                onNext: () => _next(state),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, WorkLogState state) {
    if (_pages.hasClients && _pages.page?.round() != state.currentStep) {
      _pages.animateToPage(
        state.currentStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }

    switch (state.status) {
      case WorkLogStatus.initial:
      case WorkLogStatus.loading:
        break;
      case WorkLogStatus.success:
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
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
        break;
      case WorkLogStatus.failure:
        showAmStatusDialog<void>(
          context,
          icon: HugeIcons.strokeRoundedAlert01,
          iconColor: const Color(0xFFFF453A),
          title: 'Non è stato possibile inserire il valore',
          message: 'Codice errore: ${state.errorCode ?? 'sconosciuto'}',
          actions: [
            AmDialogAction(
              label: 'Chiudi',
              color: const Color(0xFF0A84FF),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context).pop(false);
              },
            ),
            AmDialogAction(
              label: 'Riprova',
              color: _orange,
              filled: true,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.read<WorkLogBloc>().add(OnSubmitEvent());
              },
            ),
          ],
        );
        break;
    }
  }
}

class _DataStep extends StatelessWidget {
  final TextEditingController km;
  final TextEditingController customName;
  final TextEditingController notes;
  const _DataStep({
    required this.km,
    required this.customName,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return AmEdgeBlur(
      child: ListView(
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
                    'Inserisci i dati principali dell\'intervento.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BlocBuilder<WorkLogBloc, WorkLogState>(
            buildWhen: (previous, current) =>
                previous.kmValidationMessage != current.kmValidationMessage,
            builder: (context, state) => _Field(
              label: 'CHILOMETRI ATTUALI',
              controller: km,
              keyboardType: TextInputType.number,
              suffix: 'km',
              error: state.kmValidationMessage,
              onChanged: (value) => context.read<WorkLogBloc>().add(
                CurrentKmChange(currentKm: int.tryParse(value) ?? 0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<WorkLogBloc, WorkLogState>(
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel(label: 'Tipo lavoro', isRequired: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<EnumPopUp>(
                  initialValue: state.type,
                  dropdownColor: colors.surface,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _decoration(context),
                  items: EnumPopUp.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_label(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type != null) {
                      context.read<WorkLogBloc>().add(
                        OnWorkTypeChange(type: type),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<WorkLogBloc, WorkLogState>(
            builder: (context, state) {
              if (state.type != EnumPopUp.altro) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _Field(
                  label: 'NOME INTERVENTO',
                  controller: customName,
                  onChanged: (value) => context.read<WorkLogBloc>().add(
                    CustomNameChange(customName: value),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _Field(
            label: 'NOTE',
            controller: notes,
            maxLines: 4,
            onChanged: (value) =>
                context.read<WorkLogBloc>().add(NoteChange(note: value)),
          ),
        ],
      ),
    );
  }
}

class _PartsStep extends StatelessWidget {
  const _PartsStep();

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocBuilder<WorkLogBloc, WorkLogState>(
      buildWhen: (previous, current) =>
          previous.partsQuery != current.partsQuery,
      builder: (context, state) {
        final query = state.partsQuery.toLowerCase();
        final parts = kPartsCatalog.entries
            .where((part) => part.value.toLowerCase().contains(query))
            .toList();
        return AmEdgeBlur(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Cerca ricambio'),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => context.read<WorkLogBloc>().add(
                        PartsQueryChanged(query: value),
                      ),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _decoration(context).copyWith(
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          color: colors.textSecondary,
                          size: 16,
                          strokeWidth: 1.5,
                        ),
                        hintText: 'Nome del ricambio',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .9,
                  ),
                  itemCount: parts.length,
                  itemBuilder: (_, index) => _PartTile(
                    key: ValueKey(parts[index].key),
                    id: parts[index].key,
                    label: parts[index].value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PartTile extends StatelessWidget {
  final int id;
  final String label;
  const _PartTile({super.key, required this.id, required this.label});
  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocSelector<WorkLogBloc, WorkLogState, bool>(
      selector: (state) => state.selectedParts.any((part) => part.partId == id),
      builder: (context, selected) => InkWell(
        onTap: () => context.read<WorkLogBloc>().add(
          WorkLogEventCohiceTap(isSelected: selected, id: id),
        ),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected ? _orange.withValues(alpha: .22) : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _orange : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTools,
                  color: selected ? _orange : colors.textSecondary,
                  size: 28,
                  strokeWidth: 2.2,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CostsStep extends StatelessWidget {
  const _CostsStep();
  @override
  Widget build(BuildContext context) => BlocBuilder<WorkLogBloc, WorkLogState>(
    builder: (context, state) {
      return AmEdgeBlur(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: _TotalBar(total: state.partsTotal),
            ),
            Expanded(
              child: state.selectedParts.isEmpty
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
                      itemCount: state.selectedParts.length,
                      itemBuilder: (_, index) {
                        final item = state.selectedParts[index];
                        return AmSparePartCard(
                          item: item,
                          name: kPartsCatalog[item.partId] ?? 'Ricambio',
                          onRemove: () => context.read<WorkLogBloc>().add(
                            RemovePartEvent(partId: item.partId),
                          ),
                          onItemChanged: (value) => context
                              .read<WorkLogBloc>()
                              .add(UpdatePartItemEvent(item: value)),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class _TotalBar extends StatelessWidget {
  final double total;
  const _TotalBar({required this.total});
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
  final int step;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const _BottomBar({
    required this.step,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  static double _bottomPadding(BuildContext context) =>
      math.max(20.0, MediaQuery.viewPaddingOf(context).bottom + 8);

  /// Spazio verticale gia' occupato sotto al PageView. Va escluso dal
  /// calcolo dell'overlap per non restringere due volte il contenuto.
  static double extent(BuildContext context) =>
      20 + 52 + _bottomPadding(context);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final showBack = onBack != null;
    final label = step == 2 ? 'COMPLETA' : 'CONTINUA';
    final bottomPadding = _bottomPadding(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
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
                  key: ValueKey(label),
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
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? suffix;
  final String? error;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.suffix,
    this.error,
    this.maxLines = 1,
    this.onChanged,
  });
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
  final String label;
  final bool isRequired;

  const _FieldLabel({required this.label, this.isRequired = false});

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

String _label(EnumPopUp type) => switch (type) {
  EnumPopUp.aggiornaTagliando => 'Tagliando',
  EnumPopUp.aggiornaDistribuzione => 'Distribuzione',
  EnumPopUp.aggiornaCambioGomme => 'Cambio gomme',
  EnumPopUp.revisione => 'Revisione',
  EnumPopUp.pneumaticiInversione => 'Inversione gomme',
  EnumPopUp.altro => 'Altro',
};
