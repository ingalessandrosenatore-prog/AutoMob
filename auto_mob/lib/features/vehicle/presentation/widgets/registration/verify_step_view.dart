import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../bloc/vehicle_registration_bloc.dart';
import '../../bloc/vehicle_registration_event.dart';
import '../../bloc/vehicle_registration_state.dart';
import '../add_vehicle_form_step1.dart'
    show kMarcheAuto, kAnniAuto, kTipiCarburante;
import 'step_info_banner.dart';

/// Step 3 — verifica/edit dei dati trovati dal lookup targa. Se il lookup
/// e' andato a buon fine mostra una lista di sola lettura con un bottone
/// "Modifica" per correggere; se e' fallito (mock "FAIL" nella targa) parte
/// gia' in modalita' edit con i campi vuoti e un banner di avviso.
///
/// Il bottone "Continua" vive nella barra fissa della pagina root; questo
/// widget espone [submit] tramite `GlobalKey<VerifyStepViewState>`.
class VerifyStepView extends StatefulWidget {
  const VerifyStepView({super.key});

  @override
  State<VerifyStepView> createState() => VerifyStepViewState();
}

class VerifyStepViewState extends State<VerifyStepView> {
  final _modelloController = TextEditingController();
  final _cilindrataController = TextEditingController();
  final _potenzaController = TextEditingController();
  final _targaController = TextEditingController();
  String? _marca;
  String? _anno;
  String? _carburante;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    // PageView puo' montare questo step sia prima sia dopo il passaggio a
    // Verifica. Inizializziamo quindi i controller anche dallo stato corrente,
    // senza affidarci soltanto al listener del cambio pagina.
    _syncFromDraft(context.read<VehicleRegistrationBloc>().state);
  }

  @override
  void dispose() {
    _modelloController.dispose();
    _cilindrataController.dispose();
    _potenzaController.dispose();
    _targaController.dispose();
    super.dispose();
  }

  /// Il PageView monta tutti gli step in anticipo (stesso pattern del vecchio
  /// wizard), quindi initState() vedrebbe sempre il draft di default: i dati
  /// del lookup targa arrivano DOPO, mentre questo widget e' gia' montato.
  /// Risincronizziamo i campi locali solo nel momento in cui si ENTRA
  /// davvero in questo step, cosi' non sovrascriviamo eventuali modifiche
  /// manuali fatte dall'utente mentre e' gia' su questa pagina.
  void _syncFromDraft(VehicleRegistrationState state) {
    final draft = state.draft;
    _marca = draft.marca;
    _anno = draft.anno?.toString();
    _carburante = draft.carburante;
    _modelloController.text = draft.modello ?? '';
    _cilindrataController.text = draft.cilindrata?.toString() ?? '';
    _potenzaController.text = draft.potenzaCv?.toString() ?? '';
    _targaController.text = draft.targa ?? '';
    _editing = draft.datiInModifica;
  }

  void submit() {
    final bloc = context.read<VehicleRegistrationBloc>();
    final plateSource = _targaController.text.trim().isEmpty
        ? bloc.state.draft.targa ?? ''
        : _targaController.text;
    final plate = plateSource
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final valid =
        RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$').hasMatch(plate) &&
        (_marca?.isNotEmpty ?? false) &&
        _modelloController.text.trim().isNotEmpty &&
        _anno != null &&
        _carburante != null &&
        int.tryParse(_cilindrataController.text) != null &&
        int.tryParse(_potenzaController.text) != null;
    if (!valid) {
      showAmStatusDialog<void>(
        context,
        icon: HugeIcons.strokeRoundedAlert02,
        iconColor: const Color(0xFFFFB020),
        title: 'Campi obbligatori mancanti',
        message: 'Completa tutti i dati obbligatori del veicolo.',
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
    bloc.add(
      VerifyStepSubmitted(
        targa: plate,
        marca: _marca,
        modello: _modelloController.text.trim().isEmpty
            ? null
            : _modelloController.text.trim(),
        anno: _anno != null ? int.tryParse(_anno!) : null,
        carburante: _carburante,
        cilindrata: int.tryParse(_cilindrataController.text),
        potenzaCv: int.tryParse(_potenzaController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VehicleRegistrationBloc, VehicleRegistrationState>(
      listenWhen: (prev, curr) =>
          prev.currentStep != curr.currentStep && curr.currentStep == 2,
      listener: (context, state) => setState(() => _syncFromDraft(state)),
      buildWhen: (prev, curr) =>
          prev.draft != curr.draft || prev.lookupStatus != curr.lookupStatus,
      builder: (context, state) {
        final colors = AmThemeColors.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final notFound = state.draft.datiInModifica;
        return AmEdgeBlur(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'Verifica il tuo veicolo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notFound
                      ? 'Inserisci i dati del tuo veicolo.'
                      : 'Controlla i dati del tuo veicolo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const StepInfoBanner(
                  color: Color(0xFF4A90E2),
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  text:
                      'Questi dati verranno salvati nella bozza e potrai correggerli tornando indietro.',
                ),
                const SizedBox(height: 20),
                Container(
                  key: const Key('verify-data-container'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _editing
                        ? colors.background
                        : colors.cardBackground.withValues(
                            alpha: isDark ? 0.17 : 0.1,
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _editing
                          ? colors.border
                          : colors.cardBackground.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_editing)
                        Row(
                          children: [
                            AmTextField(
                              label: 'Targa',
                              placeholder: 'AA123AA',
                              controller: _targaController,
                              isRequired: true,
                              obscureText: false,
                              keyboardType: TextInputType.text,
                              height: 52,
                            ),
                          ],
                        )
                      else
                        _DataRow(
                          label: 'Targa',
                          value: state.draft.targa ?? '—',
                        ),
                      const SizedBox(height: 8),
                      if (_editing) ...[
                        Row(
                          children: [
                            AmDropdownSearch<String>(
                              label: 'Brand',
                              items: kMarcheAuto,
                              itemLabelBuilder: (item) => item,
                              value: _marca,
                              onChanged: (val) => setState(() => _marca = val),
                              placeholder: 'Seleziona...',
                              isRequired: true,
                              height: 52,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AmTextField(
                              label: 'Modello',
                              placeholder: 'es. Golf VIII',
                              controller: _modelloController,
                              isRequired: true,
                              obscureText: false,
                              keyboardType: TextInputType.text,
                              height: 52,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AmTextField(
                              label: 'Potenza (CV)',
                              placeholder: 'es. 110',
                              controller: _potenzaController,
                              isRequired: true,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              height: 52,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AmDropdownSearch<String>(
                              label: 'Anno',
                              items: kAnniAuto,
                              itemLabelBuilder: (item) => item,
                              value: _anno,
                              onChanged: (val) => setState(() => _anno = val),
                              placeholder: 'Seleziona...',
                              isRequired: true,
                              height: 52,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AmDropdownSearch<String>(
                              label: 'Carburante',
                              items: kTipiCarburante,
                              itemLabelBuilder: (item) => item,
                              value: _carburante,
                              onChanged: (val) =>
                                  setState(() => _carburante = val),
                              placeholder: 'Seleziona...',
                              isRequired: true,
                              height: 52,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AmTextField(
                              label: 'Cilindrata',
                              placeholder: 'es. 1242',
                              controller: _cilindrataController,
                              isRequired: false,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              height: 52,
                            ),
                          ],
                        ),
                      ] else ...[
                        _DataRow(label: 'Marca', value: _marca ?? '—'),
                        const SizedBox(height: 8),
                        _DataRow(
                          label: 'Modello',
                          value: _modelloController.text.isEmpty
                              ? '—'
                              : _modelloController.text,
                        ),
                        const SizedBox(height: 8),
                        _DataRow(label: 'Anno', value: _anno ?? '—'),
                        const SizedBox(height: 8),
                        _DataRow(
                          label: 'Carburante',
                          value: _carburante ?? '—',
                        ),
                        const SizedBox(height: 8),
                        _DataRow(
                          label: 'Cilindrata',
                          value: _cilindrataController.text.isEmpty
                              ? '—'
                              : '${_cilindrataController.text} cc',
                        ),
                        const SizedBox(height: 8),
                        _DataRow(
                          label: 'Potenza',
                          value: _potenzaController.text.isEmpty
                              ? '—'
                              : '${_potenzaController.text} CV',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: HugeIcon(
                      icon: _editing
                          ? HugeIcons.strokeRoundedValidationApproval
                          : HugeIcons.strokeRoundedEdit01,
                      size: 18,
                      strokeWidth: 2.2,
                    ),
                    label: Text(_editing ? 'Fatto' : 'Modifica'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE85A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Semantics(
      enabled: false,
      textField: true,
      child: Container(
        key: ValueKey('verify-readonly-$label'),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
