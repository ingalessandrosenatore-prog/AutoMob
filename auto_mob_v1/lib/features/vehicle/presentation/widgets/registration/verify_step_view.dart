import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../../core/widgets/input/drop_down_search.dart';
import '../../../../../core/widgets/input/textfield.dart';
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
  String? _marca;
  String? _anno;
  String? _carburante;
  bool _editing = false;

  @override
  void dispose() {
    _modelloController.dispose();
    _cilindrataController.dispose();
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
    _editing = state.lookupStatus == RegistrationLookupStatus.notFound;
  }

  void submit() {
    context.read<VehicleRegistrationBloc>().add(
      VerifyStepSubmitted(
        marca: _marca,
        modello: _modelloController.text.trim().isEmpty
            ? null
            : _modelloController.text.trim(),
        anno: _anno != null ? int.tryParse(_anno!) : null,
        carburante: _carburante,
        cilindrata: int.tryParse(_cilindrataController.text),
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
        final notFound =
            state.lookupStatus == RegistrationLookupStatus.notFound;
        return AmEdgeBlur(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Verifica il tuo veicolo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notFound
                      ? 'Non abbiamo trovato dati per questa targa: inseriscili a mano.'
                      : 'Controlla i dati trovati per la tua targa.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                StepInfoBanner(
                  color: notFound
                      ? const Color(0xFFFF453A)
                      : const Color(0xFF4A90E2),
                  icon: notFound ? Icons.warning_amber : Icons.info_outline,
                  text: notFound
                      ? 'Non siamo riusciti a recuperare i dati per questa targa: compilali tu, potrai sempre correggerli in seguito.'
                      : 'Questi dati verranno utilizzati per ricordarti le scadenze e calcolare il punteggio di salute del veicolo.',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151517),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  child: Column(
                    children: [
                      _DataRow(label: 'Targa', value: state.draft.targa ?? '—'),
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
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(_editing ? Icons.check : Icons.edit, size: 18),
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
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFAEAEB2),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
