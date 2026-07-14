import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/buttons/back_button.dart';
import '../../../../core/widgets/card/pup_up_head_card.dart';
import '../../../../core/widgets/input/date_picker_field.dart';
import '../../../../core/widgets/input/textfield.dart';
import 'am_interval_chips.dart';
import 'maintenance_section_card.dart';

DateTime? _parseDateStep4(String text) {
  if (text.isEmpty) return null;
  final parts = text.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

class AddVehicleFormStep4 extends StatefulWidget {
  const AddVehicleFormStep4({super.key});

  @override
  State<AddVehicleFormStep4> createState() => _AddVehicleFormStep4State();
}

class _AddVehicleFormStep4State extends State<AddVehicleFormStep4> {
  // Intervalli predefiniti proposti come choice chip (modificabili qui).
  // Il cambio gomme avviene mediamente ogni ~40k, l'inversione ogni ~15-20k.
  static const _cambioIntervalli = [30000, 40000, 50000, 60000];
  static const _inversioneIntervalli = [10000, 15000, 20000, 30000];

  final revisioneDateController = TextEditingController();
  final ultimoCambioGommeController =
      TextEditingController(); // km ultimo cambio
  final intervalloCambioController =
      TextEditingController(); // intervallo cambio
  final ultimaInversioneController =
      TextEditingController(); // km ultima inversione
  final intervalloInversioneController =
      TextEditingController(); // intervallo inversione

  // Chip attualmente evidenziata per ciascun tipo (null = nessuna / valore custom).
  int? _selectedCambio;
  int? _selectedInversione;

  // Km attuali del veicolo: letti SEMPRE freschi dal draft (inseriti in uno step
  // precedente, quindi non li posso "fotografare" in initState).
  int? get _kmAttuali => context.read<AddVehicleBloc>().state.draft.kmAttuali;

  @override
  void initState() {
    super.initState();
    // Pre-fill dei campi leggendo il draft dallo stato: se l'utente torna
    // indietro e poi rientra qui, ritrova i dati gia' inseriti.
    final d = context.read<AddVehicleBloc>().state.draft;
    if (d.kmUltimoCambioGomme != null) {
      ultimoCambioGommeController.text = d.kmUltimoCambioGomme.toString();
    }
    if (d.intervalloCambioGomme != null) {
      intervalloCambioController.text = d.intervalloCambioGomme.toString();
      _selectedCambio = d.intervalloCambioGomme;
    }
    if (d.kmUltimaInversioneGomme != null) {
      ultimaInversioneController.text = d.kmUltimaInversioneGomme.toString();
    }
    if (d.intervalloInversioneGomme != null) {
      intervalloInversioneController.text = d.intervalloInversioneGomme
          .toString();
      _selectedInversione = d.intervalloInversioneGomme;
    }
    final r = d.prossimarevisione;
    if (r != null) {
      revisioneDateController.text =
          '${r.day.toString().padLeft(2, '0')}/${r.month.toString().padLeft(2, '0')}/${r.year}';
    }
  }

  @override
  void dispose() {
    revisioneDateController.dispose();
    ultimoCambioGommeController.dispose();
    intervalloCambioController.dispose();
    ultimaInversioneController.dispose();
    intervalloInversioneController.dispose();
    super.dispose();
  }

  static const _rossoAcceso = Color(0xFFFF453A);
  static const _rossoTenue = Color(0x99FF453A);
  Color _rosso(bool error) => error ? _rossoAcceso : _rossoTenue;

  /// Avviso SEMPRE visibile sotto un campo "ultimo km": mostra i km attuali e,
  /// se il valore inserito li supera, diventa errore (error=true).
  ({String text, bool error})? _kmInfo(TextEditingController c) {
    final km = _kmAttuali;
    if (km == null) return null; // km attuali non ancora inseriti
    final v = int.tryParse(c.text);
    if (v != null && v > km) {
      return (
        text:
            'Km attuali ${fmtKm(km)}: inserisci un numero inferiore o modificalo',
        error: true,
      );
    }
    return (text: 'Km attuali: ${fmtKm(km)}', error: false);
  }

  @override
  Widget build(BuildContext context) {
    // Suffisso "km" riusato negli input (const, quindi nessun costo).
    const kmSuffix = Padding(
      padding: EdgeInsets.only(top: 14, right: 12),
      child: Text(
        "km",
        style: TextStyle(color: Color(0xFF48484A), fontWeight: FontWeight.bold),
      ),
    );

    // Avvisi km calcolati una volta per build.
    final cambioInfo = _kmInfo(ultimoCambioGommeController);
    final inversioneInfo = _kmInfo(ultimaInversioneController);

    return Stack(
      children: [
        Positioned.fill(
          child: AmEdgeBlur(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 300),
              child: Column(
                children: [
                  const SizedBox(height: 150),
                  MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedCalendar01,
                    title: "Revisione",
                    children: [
                      Row(
                        children: [
                          AmDatePickerField(
                            label: "Prossima revisione",
                            placeholder: "gg/mm/aaaa",
                            controller: revisioneDateController,
                            isRequired: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sezione Cambio gomme: ultimo km + intervallo (chip o custom).
                  MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedTire,
                    title: "Cambio gomme",
                    children: [
                      Row(
                        children: [
                          AmTextField(
                            label: "Ultimo cambio (km)",
                            placeholder: "38000",
                            controller: ultimoCambioGommeController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            errorText: cambioInfo?.text,
                            errorColor: _rosso(cambioInfo?.error ?? false),
                            suffixIcon: kmSuffix,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "OGNI QUANTI KM",
                          style: TextStyle(
                            color: Color(0xFF636366),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (
                            int i = 0;
                            i < _cambioIntervalli.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(width: 8),
                            IntervalChoiceChip(
                              label: fmtKm(_cambioIntervalli[i]),
                              selected: _selectedCambio == _cambioIntervalli[i],
                              onTap: () => setState(() {
                                _selectedCambio = _cambioIntervalli[i];
                                intervalloCambioController.text =
                                    _cambioIntervalli[i].toString();
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AmTextField(
                            label: "",
                            placeholder: "oppure inserisci km esatto",
                            controller: intervalloCambioController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(
                              () => _selectedCambio = int.tryParse(val),
                            ),
                            suffixIcon: kmSuffix,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sezione Inversione gomme: ultimo km + intervallo (chip o custom).
                  MaintenanceSectionCard(
                icon: HugeIcons.strokeRoundedCurvyLeftRightDirection,
                    title: "Inversione gomme",
                    children: [
                      Row(
                        children: [
                          AmTextField(
                            label: "Ultima inversione (km)",
                            placeholder: "40000",
                            controller: ultimaInversioneController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            errorText: inversioneInfo?.text,
                            errorColor: _rosso(inversioneInfo?.error ?? false),
                            suffixIcon: kmSuffix,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "OGNI QUANTI KM",
                          style: TextStyle(
                            color: Color(0xFF636366),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                              selected:
                                  _selectedInversione ==
                                  _inversioneIntervalli[i],
                              onTap: () => setState(() {
                                _selectedInversione = _inversioneIntervalli[i];
                                intervalloInversioneController.text =
                                    _inversioneIntervalli[i].toString();
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AmTextField(
                            label: "",
                            placeholder: "oppure inserisci km esatto",
                            controller: intervalloInversioneController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(
                              () => _selectedInversione = int.tryParse(val),
                            ),
                            suffixIcon: kmSuffix,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: WizardHeader(
      stepIcon: HugeIcons.strokeRoundedCalendar01,
            stepNumber: 4,
            totalSteps: 5,
            title: "Scadenze",
            onClose: () => context.pop('/home'),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: AmOutlinedButton(
                    label: "Indietro",
                    color: const Color(0xFF4A90E2),
                    onPressed: () =>
                        context.read<AddVehicleBloc>().add(StepBackPressed()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AmMainFab(
                    label: "Continua",
                    height: 60,
                    width: 180,
                    color: const Color(0xFFE85A1A),
              icon: HugeIcons.strokeRoundedArrowRight01,
                    onPressed: () {
                      // Blocco l'avanzamento se un "ultimo km" supera i km attuali.
                      final bloccato =
                          (_kmInfo(ultimoCambioGommeController)?.error ??
                              false) ||
                          (_kmInfo(ultimaInversioneController)?.error ?? false);
                      if (bloccato) {
                        setState(() {});
                        return;
                      }
                      context.read<AddVehicleBloc>().add(
                        Step4Submitted(
                          prossimarevisione: _parseDateStep4(
                            revisioneDateController.text,
                          ),
                          kmUltimoCambioGomme: int.tryParse(
                            ultimoCambioGommeController.text,
                          ),
                          intervalloCambioGomme: int.tryParse(
                            intervalloCambioController.text,
                          ),
                          kmUltimaInversioneGomme: int.tryParse(
                            ultimaInversioneController.text,
                          ),
                          intervalloInversioneGomme: int.tryParse(
                            intervalloInversioneController.text,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
