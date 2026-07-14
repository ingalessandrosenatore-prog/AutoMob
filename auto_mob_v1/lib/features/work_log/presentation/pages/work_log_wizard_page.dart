import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import '../../../../core/constants/parts_catalog.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/am_theme_colors.dart';
import '../../../../core/types/enum_pop_up.dart';
import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/back_button.dart';
import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/buttons/soft_button.dart';
import '../../../../core/widgets/card/am_spare_part_card.dart';
import '../../../../core/widgets/hero/am_fab_hero.dart';
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
  final String heroTag;

  const WorkLogWizardPage({
    super.key,
    required this.vehicleId,
    required this.currentKm,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocProvider(
      create: (_) {
        final bloc = sl<WorkLogBloc>(param1: vehicleId);
        bloc.add(InitKm(vehicleKm: currentKm));
        return bloc;
      },
      child: PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: colors.background,
          resizeToAvoidBottomInset: false,
          body: _WorkLogWizardBody(heroTag: heroTag),
        ),
      ),
    );
  }
}

class _WorkLogWizardBody extends StatefulWidget {
  final String heroTag;
  const _WorkLogWizardBody({required this.heroTag});

  @override
  State<_WorkLogWizardBody> createState() => _WorkLogWizardBodyState();
}

class _WorkLogWizardBodyState extends State<_WorkLogWizardBody> {
  late final PageController _pages;
  final _km = TextEditingController();
  final _customName = TextEditingController();
  final _notes = TextEditingController();
  String _query = '';
  String? _kmError;

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkLogBloc>().state;
    _pages = PageController(initialPage: state.currentStep);
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
      setState(() => _kmError = 'Inserisci almeno ${state.vehicleKm} km');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft lavoro pronto per il salvataggio')),
      );
      return;
    }
    context.read<WorkLogBloc>().add(
      WorkLogWizardStepChanged(state.currentStep + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkLogBloc, WorkLogState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep,
      listener: (_, state) => _pages.animateToPage(
        state.currentStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      ),
      builder: (context, state) {
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
                        child: SizedBox(width: 45, height: 45),
                      ),
                    ),
                    const Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            'AGGIUNGI LAVORO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: [
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
                        child: AmFabHero(
                          tag: widget.heroTag,
                          child: OCLiquidGlassGroup(
                            settings: const OCLiquidGlassSettings(
                              refractStrength: -0.130,
                              blurRadiusPx: 1.0,
                              specStrength: 0,
                              specWidth: 0.0,
                              specAngle: 145,
                              blendPx: 20,
                              specPower: 10,
                            ),
                            child: AmSoftButton(
                              width: 45,
                              height: 45,
                              color: _orange,
                              icon: HugeIcons.strokeRoundedAdd01,
                              iconTurns: 0.125,
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ),
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
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DataStep(
                      km: _km,
                      customName: _customName,
                      notes: _notes,
                      kmError: _kmError,
                    ),
                    _PartsStep(
                      query: _query,
                      onQueryChanged: (value) => setState(() => _query = value),
                    ),
                    const _CostsStep(),
                  ],
                ),
              ),
              _BottomBar(
                step: state.currentStep,
                onBack: state.currentStep == 0
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
}

class _DataStep extends StatelessWidget {
  final TextEditingController km;
  final TextEditingController customName;
  final TextEditingController notes;
  final String? kmError;
  const _DataStep({
    required this.km,
    required this.customName,
    required this.notes,
    required this.kmError,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return ListView(
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
        _Field(
          label: 'CHILOMETRI ATTUALI',
          controller: km,
          keyboardType: TextInputType.number,
          suffix: 'km',
          error: kmError,
          onChanged: (value) => context.read<WorkLogBloc>().add(
            CurrentKmChange(currentKm: int.tryParse(value) ?? 0),
          ),
        ),
        const SizedBox(height: 20),
        BlocBuilder<WorkLogBloc, WorkLogState>(
          builder: (context, state) => DropdownButtonFormField<EnumPopUp>(
            initialValue: state.type,
            dropdownColor: colors.surface,
            style: TextStyle(color: colors.textPrimary),
            decoration: _decoration(context, 'TIPO LAVORO'),
            items: EnumPopUp.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(_label(type))),
                )
                .toList(),
            onChanged: (type) {
              if (type != null) {
                context.read<WorkLogBloc>().add(OnWorkTypeChange(type: type));
              }
            },
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
    );
  }
}

class _PartsStep extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  const _PartsStep({required this.query, required this.onQueryChanged});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final parts = kPartsCatalog.entries
        .where((part) => part.value.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: TextField(
            onChanged: onQueryChanged,
            style: TextStyle(color: colors.textPrimary),
            decoration: _decoration(context, 'CERCA RICAMBIO').copyWith(
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                color: colors.textSecondary,
                size: 18,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
        Expanded(
          child: AmEdgeBlur(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .82,
              ),
              itemCount: parts.length,
              itemBuilder: (_, index) =>
                  _PartTile(id: parts[index].key, label: parts[index].value),
            ),
          ),
        ),
      ],
    );
  }
}

class _PartTile extends StatelessWidget {
  final int id;
  final String label;
  const _PartTile({required this.id, required this.label});
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
      final total = state.selectedParts.fold<double>(
        0,
        (sum, part) => sum + part.quantity * (part.unitPrice ?? 0),
      );
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: _TotalBar(total: total),
          ),
          Expanded(
            child: AmEdgeBlur(
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
          ),
        ],
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
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const _BottomBar({
    required this.step,
    required this.onBack,
    required this.onNext,
  });
  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final showBack = onBack != null;
    final label = step == 2 ? 'COMPLETA' : 'CONTINUA';
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              width: showBack ? 130 : 0,
              margin: EdgeInsets.only(right: showBack ? 16 : 0),
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showBack ? 1 : 0,
                child: SizedBox(
                  width: 130,
                  height: 52,
                  child: AmOutlinedButton(
                    label: 'INDIETRO',
                    color: colors.accent,
                    fillColor: colors.surface,
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
                  onPressed: onNext,
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: colors.textPrimary),
      decoration: _decoration(
        context,
        label,
      ).copyWith(suffixText: suffix, errorText: error),
    );
  }
}

InputDecoration _decoration(BuildContext context, String label) {
  final colors = AmThemeColors.of(context);
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: colors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: colors.surface,
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
