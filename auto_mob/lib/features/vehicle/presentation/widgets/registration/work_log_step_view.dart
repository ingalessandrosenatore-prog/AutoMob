import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../../core/theme/am_theme_colors.dart';
import '../../../../../core/widgets/icons/am_engine_icon.dart';
import '../../../../../core/widgets/input/date_picker_field.dart';
import '../../../../../core/widgets/input/textfield.dart';
import '../../../../../core/widgets/dialog/am_status_dialog.dart';
import '../../bloc/vehicle_registration_bloc.dart';
import '../../bloc/vehicle_registration_event.dart';
import '../../bloc/vehicle_registration_state.dart';
import '../am_interval_chips.dart';
import '../maintenance_section_card.dart';
import 'step_info_banner.dart';

DateTime? _parseData(String text) {
  if (text.isEmpty) return null;
  final parts = text.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

/// Step 4 — ultimi lavori svolti: riusa gli stessi blocchi
/// (MaintenanceSectionCard/IntervalChoiceChip) di tagliando, distribuzione,
/// cambio/inversione gomme e revisione gia' presenti nel wizard a pop-up.
///
/// Il bottone "Continua" vive nella barra fissa della pagina root; questo
/// widget espone [submit] tramite `GlobalKey<WorkLogStepViewState>`.
class WorkLogStepView extends StatefulWidget {
  const WorkLogStepView({super.key});

  @override
  State<WorkLogStepView> createState() => WorkLogStepViewState();
}

class WorkLogStepViewState extends State<WorkLogStepView> {
  static const _tagliandoIntervalli = [10000, 15000, 20000, 30000];
  static const _distribuzioneIntervalli = [60000, 90000, 120000, 150000];
  static const _cambioIntervalli = [30000, 40000, 50000, 60000];
  static const _inversioneIntervalli = [10000, 15000, 20000, 30000];

  final _kmAttualiController = TextEditingController();
  final _kmTagliandoController = TextEditingController();
  final _intervalloTagliandoController = TextEditingController();
  final _kmDistribuzioneController = TextEditingController();
  final _intervalloDistribuzioneController = TextEditingController();
  final _revisioneDateController = TextEditingController();
  final _kmCambioGommeController = TextEditingController();
  final _intervalloCambioController = TextEditingController();
  final _kmInversioneController = TextEditingController();
  final _intervalloInversioneController = TextEditingController();

  int? _selTagliando;
  int? _selDistribuzione;
  int? _selCambio;
  int? _selInversione;

  String _dateText(DateTime? date) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _syncFromDraft(VehicleRegistrationState state) {
    final draft = state.draft;
    _kmAttualiController.text = draft.kmAttuali?.toString() ?? '';
    _kmTagliandoController.text = draft.kmUltimoTagliando?.toString() ?? '';
    _intervalloTagliandoController.text =
        draft.intervalloUltimoTagliando?.toString() ?? '';
    _kmDistribuzioneController.text =
        draft.kmUltimaDistribuzione?.toString() ?? '';
    _intervalloDistribuzioneController.text =
        draft.intervalloUltimaDistribuzione?.toString() ?? '';
    _revisioneDateController.text = _dateText(draft.prossimarevisione);
    _kmCambioGommeController.text = draft.kmUltimoCambioGomme?.toString() ?? '';
    _intervalloCambioController.text =
        draft.intervalloCambioGomme?.toString() ?? '';
    _kmInversioneController.text =
        draft.kmUltimaInversioneGomme?.toString() ?? '';
    _intervalloInversioneController.text =
        draft.intervalloInversioneGomme?.toString() ?? '';
    _selTagliando = draft.intervalloUltimoTagliando;
    _selDistribuzione = draft.intervalloUltimaDistribuzione;
    _selCambio = draft.intervalloCambioGomme;
    _selInversione = draft.intervalloInversioneGomme;
  }

  @override
  void dispose() {
    _kmAttualiController.dispose();
    _kmTagliandoController.dispose();
    _intervalloTagliandoController.dispose();
    _kmDistribuzioneController.dispose();
    _intervalloDistribuzioneController.dispose();
    _revisioneDateController.dispose();
    _kmCambioGommeController.dispose();
    _intervalloCambioController.dispose();
    _kmInversioneController.dispose();
    _intervalloInversioneController.dispose();
    super.dispose();
  }

  int? get _kmAttuali => int.tryParse(_kmAttualiController.text);

  ({String text, bool error})? _kmInfo(TextEditingController c) {
    final km = _kmAttuali;
    if (km == null) return null;
    final v = int.tryParse(c.text);
    if (v != null && v > km) {
      return (
        text: 'Km attuali ${fmtKm(km)}: inserisci un numero inferiore',
        error: true,
      );
    }
    return (text: 'Km attuali: ${fmtKm(km)}', error: false);
  }

  bool get _bloccato =>
      (_kmInfo(_kmTagliandoController)?.error ?? false) ||
      (_kmInfo(_kmDistribuzioneController)?.error ?? false) ||
      (_kmInfo(_kmCambioGommeController)?.error ?? false) ||
      (_kmInfo(_kmInversioneController)?.error ?? false);

  void submit() {
    if (_bloccato) {
      setState(() {});
      showAmStatusDialog<void>(
        context,
        icon: HugeIcons.strokeRoundedAlert02,
        iconColor: const Color(0xFFFFB020),
        title: 'Chilometri non validi',
        message:
            'I chilometri degli ultimi interventi non possono superare i chilometri attuali.',
        actions: [
          AmDialogAction(
            label: 'Chiudi',
            color: const Color(0xFFE85A1A),
            filled: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
      return;
    }
    context.read<VehicleRegistrationBloc>().add(
      WorkLogStepSubmitted(
        kmAttuali: _kmAttuali,
        kmUltimoTagliando: int.tryParse(_kmTagliandoController.text),
        intervalloTagliando: int.tryParse(_intervalloTagliandoController.text),
        kmUltimaDistribuzione: int.tryParse(_kmDistribuzioneController.text),
        intervalloUltimaDistribuzione: int.tryParse(
          _intervalloDistribuzioneController.text,
        ),
        prossimarevisione: _parseData(_revisioneDateController.text),
        kmUltimoCambioGomme: int.tryParse(_kmCambioGommeController.text),
        intervalloCambioGomme: int.tryParse(_intervalloCambioController.text),
        kmUltimaInversioneGomme: int.tryParse(_kmInversioneController.text),
        intervalloInversioneGomme: int.tryParse(
          _intervalloInversioneController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final tagInfo = _kmInfo(_kmTagliandoController);
    final distInfo = _kmInfo(_kmDistribuzioneController);
    final cambioInfo = _kmInfo(_kmCambioGommeController);
    final inversioneInfo = _kmInfo(_kmInversioneController);

    return BlocListener<VehicleRegistrationBloc, VehicleRegistrationState>(
      listenWhen: (previous, current) =>
          previous.currentStep != current.currentStep &&
          current.currentStep == 3,
      listener: (context, state) => setState(() => _syncFromDraft(state)),
      child: AmEdgeBlur(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const StepInfoBanner(
                color: Color(0xFF4A90E2),
                icon: HugeIcons.strokeRoundedTools,
                text:
                    'Inserisci gli ultimi lavori svolti per calcolare le prossime scadenze.',
              ),
              const SizedBox(height: 20),
              MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedDashboardSpeed02,
                title: 'Km attuali',
                iconColor: colors.accent,
                uppercaseTitle: true,
                children: [
                  Row(
                    children: [
                      AmTextField(
                        label: 'Chilometri attuali',
                        placeholder: '85000',
                        controller: _kmAttualiController,
                        isRequired: true,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        height: 52,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedTools,
                title: 'Ultimo tagliando',
                iconColor: colors.accent,
                uppercaseTitle: true,
                children: [
                  Row(
                    children: [
                      AmTextField(
                        label: 'Km effettuato',
                        placeholder: '45000',
                        controller: _kmTagliandoController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        errorText: tagInfo?.text,
                        errorColor: (tagInfo?.error ?? false)
                            ? const Color(0xFFFF453A)
                            : const Color(0x99FF453A),
                        height: 52,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (int i = 0; i < _tagliandoIntervalli.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        IntervalChoiceChip(
                          label: fmtKm(_tagliandoIntervalli[i]),
                          selected: _selTagliando == _tagliandoIntervalli[i],
                          onTap: () => setState(() {
                            _selTagliando = _tagliandoIntervalli[i];
                            _intervalloTagliandoController.text =
                                _tagliandoIntervalli[i].toString();
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MaintenanceSectionCard(
                // Nessun corrispettivo diretto trovato in HugeIcons 1.1.7.
                icon: Icons.link,
                title: 'Distribuzione / Cinghia',
                iconColor: colors.accent,
                uppercaseTitle: true,
                iconWidget: AmEngineIcon(size: 18, color: colors.accent),
                children: [
                  Row(
                    children: [
                      AmTextField(
                        label: 'Effettuato a km',
                        placeholder: '130000',
                        controller: _kmDistribuzioneController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        errorText: distInfo?.text,
                        errorColor: (distInfo?.error ?? false)
                            ? const Color(0xFFFF453A)
                            : const Color(0x99FF453A),
                        height: 52,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (
                        int i = 0;
                        i < _distribuzioneIntervalli.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(width: 8),
                        IntervalChoiceChip(
                          label: fmtKm(_distribuzioneIntervalli[i]),
                          selected:
                              _selDistribuzione == _distribuzioneIntervalli[i],
                          onTap: () => setState(() {
                            _selDistribuzione = _distribuzioneIntervalli[i];
                            _intervalloDistribuzioneController.text =
                                _distribuzioneIntervalli[i].toString();
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedCalendar01,
                title: 'Revisione',
                iconColor: colors.accent,
                uppercaseTitle: true,
                children: [
                  Row(
                    children: [
                      AmDatePickerField(
                        label: 'Prossima revisione',
                        placeholder: 'gg/mm/aaaa',
                        controller: _revisioneDateController,
                        isRequired: false,
                        height: 52,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedTire,
                title: 'Cambio gomme',
                iconColor: colors.accent,
                uppercaseTitle: true,
                children: [
                  Row(
                    children: [
                      AmTextField(
                        label: 'Ultimo cambio (km)',
                        placeholder: '38000',
                        controller: _kmCambioGommeController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        errorText: cambioInfo?.text,
                        errorColor: (cambioInfo?.error ?? false)
                            ? const Color(0xFFFF453A)
                            : const Color(0x99FF453A),
                        height: 52,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (int i = 0; i < _cambioIntervalli.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        IntervalChoiceChip(
                          label: fmtKm(_cambioIntervalli[i]),
                          selected: _selCambio == _cambioIntervalli[i],
                          onTap: () => setState(() {
                            _selCambio = _cambioIntervalli[i];
                            _intervalloCambioController.text =
                                _cambioIntervalli[i].toString();
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedCurvyLeftRightDirection,
                title: 'Inversione gomme',
                iconColor: colors.accent,
                uppercaseTitle: true,
                children: [
                  Row(
                    children: [
                      AmTextField(
                        label: 'Ultima inversione (km)',
                        placeholder: '40000',
                        controller: _kmInversioneController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        errorText: inversioneInfo?.text,
                        errorColor: (inversioneInfo?.error ?? false)
                            ? const Color(0xFFFF453A)
                            : const Color(0x99FF453A),
                        height: 52,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (
                        int i = 0;
                        i < _inversioneIntervalli.length;
                        i++
                      ) ...[
                        if (i > 0) const SizedBox(width: 8),
                        IntervalChoiceChip(
                          label: fmtKm(_inversioneIntervalli[i]),
                          selected: _selInversione == _inversioneIntervalli[i],
                          onTap: () => setState(() {
                            _selInversione = _inversioneIntervalli[i];
                            _intervalloInversioneController.text =
                                _inversioneIntervalli[i].toString();
                          }),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
