import 'dart:ui';

import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/Buttons/backButton.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/Textfield.dart';

class AddVehicleFormStep3 extends StatelessWidget {
  const AddVehicleFormStep3({super.key});

  @override
  Widget build(BuildContext context) {
    final potenzaController = TextEditingController();
    final cilindrataController = TextEditingController();
    final kmController = TextEditingController();

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: Column(

              children: [
                SizedBox(height: 150),
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
                        const SizedBox(width: 16),
                        AmTextField(
                          label: "Cilindrata",
                          placeholder: "1500",
                          controller: cilindrataController,
                          isRequired: false,
                          obscureText: false,
                          keyboardType: TextInputType.number,
                          suffixIcon: Text(
                            "CC",
                            style: TextStyle(
                              color: Color(0xFF48484A),
                              fontWeight: FontWeight.bold,
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
                        style: TextStyle(
                          color: Color(0xFF636366),
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 15),
              child: WizardHeader(
                stepIcon: Icons.speed,
                stepNumber: 3,
                totalSteps: 5,
                title: "Dettagli tecnici",
                onClose: () =>
                    context.pop('/home'),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: AmOutlinedButton(
                        label: "Indietro",
                        color: const Color(0xFF4A90E2),
                        onPressed: () => context.read<AddVehicleBloc>().add(
                          StepBackPressed(),
                        ),
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
                          context.read<AddVehicleBloc>().add(
                            Step3Submitted(
                              potenzaCv: int.tryParse(potenzaController.text),
                              cilindrata: int.tryParse(
                                cilindrataController.text,
                              ),
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
          ),
        ),
      ],
    );
  }
}
