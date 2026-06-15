import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/Blur/AmEdgeBlur.dart';
import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/Buttons/backButton.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/Textfield.dart';
import 'AmIntervalChips.dart';
import 'MaintenanceSectionCard.dart';

class AddVehicleFormStep2 extends StatefulWidget {
  const AddVehicleFormStep2({super.key});

  @override
  State<AddVehicleFormStep2> createState() => _AddVehicleFormStep2State();
}

class _AddVehicleFormStep2State extends State<AddVehicleFormStep2> {
  // Intervalli predefiniti come choice chip (modificabili qui).
  static const _tagliandoIntervalli = [10000, 15000, 20000, 30000];
  static const _distribuzioneIntervalli = [60000, 90000, 120000, 150000];

  final kmTagliandoController = TextEditingController();
  final intervalloTagliandoController = TextEditingController();
  final kmDistribuzioneController = TextEditingController();
  final intervalloDistribuzioneController = TextEditingController();

  int? _selTagliando;
  int? _selDistribuzione;

  // True dopo il primo tentativo di "Continua": abilita gli errori obbligatori.
  bool _submitted = false;

  // Km attuali del veicolo: letti SEMPRE freschi dal draft (vengono inseriti
  // nello step precedente, quindi non li posso "fotografare" in initState).
  int? get _kmAttuali => context.read<AddVehicleBloc>().state.draft.kmAttuali;

  @override
  void initState() {
    super.initState();
    // Pre-fill dal draft: tornando indietro ritrovo i dati gia' inseriti.
    final d = context.read<AddVehicleBloc>().state.draft;
    if (d.kmUltimoTagliando != null) {
      kmTagliandoController.text = d.kmUltimoTagliando.toString();
    }
    if (d.intervalloUltimoTagliando != null) {
      intervalloTagliandoController.text = d.intervalloUltimoTagliando.toString();
      _selTagliando = d.intervalloUltimoTagliando;
    }
    if (d.kmUltimaDistribuzione != null) {
      kmDistribuzioneController.text = d.kmUltimaDistribuzione.toString();
    }
    if (d.intervalloUltimaDistribuzione != null) {
      intervalloDistribuzioneController.text =
          d.intervalloUltimaDistribuzione.toString();
      _selDistribuzione = d.intervalloUltimaDistribuzione;
    }
  }

  @override
  void dispose() {
    kmTagliandoController.dispose();
    intervalloTagliandoController.dispose();
    kmDistribuzioneController.dispose();
    intervalloDistribuzioneController.dispose();
    super.dispose();
  }

  int? _i(TextEditingController c) => int.tryParse(c.text);

  /// "Prossima sostituzione prevista" = ultimo km + intervallo.
  String _prossima(TextEditingController km, TextEditingController interv) =>
      '${fmtKm((_i(km) ?? 0) + (_i(interv) ?? 0))} km';

  static const _rossoAcceso = Color(0xFFFF453A);
  static const _rossoTenue = Color(0x99FF453A);
  Color _rosso(bool error) => error ? _rossoAcceso : _rossoTenue;

  /// Avviso SEMPRE visibile sotto un campo "ultimo km": mostra i km attuali e,
  /// se il valore inserito li supera, diventa errore (error=true).
  ({String text, bool error})? _kmInfo(TextEditingController c) {
    final km = _kmAttuali;
    if (km == null) return null; // km attuali non ancora inseriti
    final v = _i(c);
    if (v != null && v > km) {
      return (
        text: 'Km attuali ${fmtKm(km)}: inserisci un numero inferiore o modificalo',
        error: true,
      );
    }
    return (text: 'Km attuali: ${fmtKm(km)}', error: false);
  }

  /// Distribuzione: prima l'obbligatorieta', poi l'avviso km.
  ({String text, bool error})? _distribuzioneInfo() {
    if (_submitted && kmDistribuzioneController.text.trim().isEmpty) {
      return (text: 'Campo obbligatorio: inserisci i km della distribuzione', error: true);
    }
    return _kmInfo(kmDistribuzioneController);
  }

  @override
  Widget build(BuildContext context) {
    const kmSuffix = Padding(
      padding: EdgeInsets.only(top: 14),
      child: Text("km",
          style: TextStyle(color: Color(0xFF48484A), fontWeight: FontWeight.bold)),
    );

    // Avvisi km calcolati una volta per build.
    final tagInfo = _kmInfo(kmTagliandoController);
    final distInfo = _distribuzioneInfo();

    return Stack(
      children: [
        Positioned.fill(
          child: AmEdgeBlur(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 300),
              child: Column(
                children: [
                  const SizedBox(height: 150),

                  // 1. Tagliando
                  MaintenanceSectionCard(
                    icon: Icons.handyman,
                    title: "Ultimo tagliando",
                    children: [
                      Row(
                        children: [
                          AmTextField(
                            label: "Km effettuato",
                            placeholder: "45000",
                            controller: kmTagliandoController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            errorText: tagInfo?.text,
                            errorColor: _rosso(tagInfo?.error ?? false),
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
                          for (int i = 0; i < _tagliandoIntervalli.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            IntervalChoiceChip(
                              label: fmtKm(_tagliandoIntervalli[i]),
                              selected: _selTagliando == _tagliandoIntervalli[i],
                              onTap: () => setState(() {
                                _selTagliando = _tagliandoIntervalli[i];
                                intervalloTagliandoController.text =
                                    _tagliandoIntervalli[i].toString();
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AmTextField(
                            label: "Intervallo di km",
                            placeholder: "15000",
                            controller: intervalloTagliandoController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(
                                () => _selTagliando = int.tryParse(val)),
                            suffixIcon: kmSuffix,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Prossima sostituzione prevista a: "
                          "${_prossima(kmTagliandoController, intervalloTagliandoController)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. Distribuzione
                  MaintenanceSectionCard(
                    icon: Icons.link,
                    title: "Distribuzione / Cinghia",
                    children: [
                      Row(
                        children: [
                          AmTextField(
                            label: "Effettuato a km",
                            placeholder: "130000",
                            controller: kmDistribuzioneController,
                            isRequired: true,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            errorText: distInfo?.text,
                            errorColor: _rosso(distInfo?.error ?? false),
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
                          for (int i = 0;
                              i < _distribuzioneIntervalli.length;
                              i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            IntervalChoiceChip(
                              label: fmtKm(_distribuzioneIntervalli[i]),
                              selected:
                                  _selDistribuzione == _distribuzioneIntervalli[i],
                              onTap: () => setState(() {
                                _selDistribuzione = _distribuzioneIntervalli[i];
                                intervalloDistribuzioneController.text =
                                    _distribuzioneIntervalli[i].toString();
                              }),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AmTextField(
                            label: "Sostituzione prevista ogni",
                            placeholder: "60000",
                            controller: intervalloDistribuzioneController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (val) => setState(
                                () => _selDistribuzione = int.tryParse(val)),
                            suffixIcon: kmSuffix,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Prossima sostituzione prevista a: "
                          "${_prossima(kmDistribuzioneController, intervalloDistribuzioneController)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
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
            stepIcon: Icons.build,
            stepNumber: 3,
            totalSteps: 5,
            title: "Storico manutenzioni",
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
                    icon: Icons.chevron_right,
                    onPressed: () {
                      setState(() => _submitted = true);
                      // Blocco se: km oltre attuali, oppure distribuzione vuota.
                      final bloccato = (_kmInfo(kmTagliandoController)?.error ?? false) ||
                          (_distribuzioneInfo()?.error ?? false);
                      if (bloccato) return;
                      context.read<AddVehicleBloc>().add(
                            Step2Submitted(
                              intervalloTagliando:
                                  int.tryParse(intervalloTagliandoController.text),
                              kmUltimoTagliando:
                                  int.tryParse(kmTagliandoController.text),
                              intervalloUltimaDistribuzione: int.tryParse(
                                  intervalloDistribuzioneController.text),
                              kmUltimaDistribuzione:
                                  int.tryParse(kmDistribuzioneController.text),
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
