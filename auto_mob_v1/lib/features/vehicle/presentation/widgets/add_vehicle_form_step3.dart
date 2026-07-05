import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/buttons/back_button.dart';
import '../../../../core/widgets/card/pup_up_head_card.dart';
import '../../../../core/widgets/input/textfield.dart';

class AddVehicleFormStep3 extends StatefulWidget {
  const AddVehicleFormStep3({super.key});

  @override
  State<AddVehicleFormStep3> createState() => _AddVehicleFormStep3State();
}

class _AddVehicleFormStep3State extends State<AddVehicleFormStep3> {
  final potenzaController = TextEditingController();
  final cilindrataController = TextEditingController();
  final kmController = TextEditingController();

  // True dopo il primo "Continua": abilita l'errore del campo obbligatorio.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill dal draft: tornando indietro ritrovo i dati gia' inseriti.
    final d = context.read<AddVehicleBloc>().state.draft;
    if (d.potenzaCv != null) potenzaController.text = d.potenzaCv.toString();
    if (d.cilindrata != null) cilindrataController.text = d.cilindrata.toString();
    if (d.kmAttuali != null) kmController.text = d.kmAttuali.toString();
  }

  @override
  void dispose() {
    potenzaController.dispose();
    cilindrataController.dispose();
    kmController.dispose();
    super.dispose();
  }

  String? _kmError() {
    if (_submitted && kmController.text.trim().isEmpty) {
      return 'Campo obbligatorio: inserisci i km attuali';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AmEdgeBlur(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 300),
              child: Column(
                children: [
                  const SizedBox(height: 150),
                  Column(
                    children: [
                      Row(
                        children: [
                          AmTextField(
                            label: "Potenza",
                            placeholder: "150",
                            controller: potenzaController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(top: 14, right: 12),
                              child: Text(
                                "CV",
                                style: TextStyle(
                                  color: Color(0xFF48484A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          AmTextField(
                            label: "Cilindrata",
                            placeholder: "1500",
                            controller: cilindrataController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(top: 14, right: 12),
                              child: Text(
                                "CC",
                                style: TextStyle(
                                  color: Color(0xFF48484A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          AmTextField(
                            label: "Chilometri attuali",
                            placeholder: "45230",
                            controller: kmController,
                            isRequired: true,
                            obscureText: false,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            errorText: _kmError(),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(top: 14, right: 12),
                              child: Text(
                                "km",
                                style: TextStyle(
                                  color: Color(0xFF48484A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Aggiornalo dal cruscotto della tua auto",
                          style: TextStyle(color: Color(0xFF636366), fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 30),
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
            stepIcon: Icons.speed,
            stepNumber: 2,
            totalSteps: 5,
            title: "Dettagli tecnici",
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
                      // Km attuali obbligatori: senza, non avanzo.
                      if (kmController.text.trim().isEmpty) return;
                      context.read<AddVehicleBloc>().add(
                            Step3Submitted(
                              potenzaCv: int.tryParse(potenzaController.text),
                              cilindrata: int.tryParse(cilindrataController.text),
                              kmAttuali: int.tryParse(kmController.text),
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
