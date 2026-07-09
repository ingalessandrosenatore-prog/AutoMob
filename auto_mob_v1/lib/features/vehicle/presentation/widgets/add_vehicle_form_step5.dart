import 'dart:io';

import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/buttons/back_button.dart';
import '../../../../core/widgets/card/pup_up_head_card.dart';
import '../../../../core/widgets/input/textfield.dart';
import 'maintenance_section_card.dart';

class AddVehicleFormStep5 extends StatefulWidget {
  const AddVehicleFormStep5({super.key});

  @override
  State<AddVehicleFormStep5> createState() => _AddVehicleFormStep5State();
}

class _AddVehicleFormStep5State extends State<AddVehicleFormStep5> {
  final codiceMeccanicoController = TextEditingController();
  XFile? _image;
  final picker =  ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null){
      setState(() {
        _image = pickedFile;
      });
    }
  }



  @override
  Widget build(BuildContext context) {


    return Column(

      children: [
        WizardHeader(
          stepIcon: Icons.camera_alt_outlined,
          stepNumber: 5,
          totalSteps: 5,
          title: "Foto e Officina",
          onClose: () => context.pop('/home'),
        ),

        Expanded(
          child: AmEdgeBlur(
            child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 300,
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                            pickImage();
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Foto del veicolo",
                        style: TextStyle(
                          color: Color(0xFF636366),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                MaintenanceSectionCard(
                  icon: Icons.link,
                  title: "Connetti meccanico",
                  children: [
                    const Text(
                      "Inserisci il codice fornito dal tuo meccanico per permettergli di aggiornare i dati del veicolo.",
                      style: TextStyle(
                        color: Color(0xFF636366),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        AmTextField(
                          label: "Codice meccanico",
                          placeholder: "MECH-XXXX",
                          controller: codiceMeccanicoController,
                          isRequired: false,
                          obscureText: false,
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1412),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: "Potrai collegare il meccanico in seguito dalla sezione "),
                              TextSpan(
                                text: "Servizi.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(
                      child: AmOutlinedButton(
                        label: "Indietro",
                        color: const Color(0xFF4A90E2),
                        onPressed: () => context.read<AddVehicleBloc>().add(StepBackPressed()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AmMainFab(
                        label: "Registra",
                        height: 60,
                        width: 180,
                        color: const Color(0xFFE85A1A),
                        icon: Icons.check,
                        onPressed: () {
                          context.read<AddVehicleBloc>().add(
                            SaveWizard(
                              codiceMeccanico: codiceMeccanicoController.text.isEmpty
                                  ? null
                                  : codiceMeccanicoController.text,
                              fotoFile: _image != null ? File(_image!.path) : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}
