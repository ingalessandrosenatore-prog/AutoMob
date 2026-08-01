import 'dart:io';

import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/back_button.dart';
import '../../../../core/widgets/card/pup_up_head_card.dart';
import 'maintenance_section_card.dart';

class AddVehicleFormStep5 extends StatefulWidget {
  const AddVehicleFormStep5({super.key});

  @override
  State<AddVehicleFormStep5> createState() => _AddVehicleFormStep5State();
}

class _AddVehicleFormStep5State extends State<AddVehicleFormStep5> {
  final codiceMeccanicoController = TextEditingController();
  XFile? _image;
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Column(
      children: [
        WizardHeader(
          // Nessun corrispettivo diretto trovato in HugeIcons 1.1.7.
          stepIcon: HugeIcons.strokeRoundedAlbum02,
          stepNumber: 5,
          totalSteps: 5,
          title: "Foto e Officina",
          onClose: () => context.pop('/home'),
        ),

        Expanded(
          child: AmEdgeBlur(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 300),
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
                              color: colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.border,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Foto del veicolo",
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  MaintenanceSectionCard(
                    // Nessun corrispettivo diretto trovato in HugeIcons 1.1.7.
                    icon: Icons.link,
                    title: "Connetti meccanico",
                    children: [
                      Text(
                        "Inserisci il codice fornito dal tuo meccanico per permettergli di aggiornare i dati del veicolo.",
                        style: TextStyle(
                          color: colors.textSecondary,
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
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
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
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            color: Colors.white,
                            size: 16,
                            strokeWidth: 2.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      "Potrai collegare il meccanico in seguito dalla sezione ",
                                ),
                                TextSpan(
                                  text: "Servizi.",
                                  style: TextStyle(
                                    color: colors.textPrimary,
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
                          onPressed: () => context.read<AddVehicleBloc>().add(
                            StepBackPressed(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AmMainFab(
                          label: "Registra",
                          height: 60,
                          width: 180,
                          color: const Color(0xFFE85A1A),
                          icon: HugeIcons.strokeRoundedValidationApproval,
                          onPressed: () {
                            context.read<AddVehicleBloc>().add(
                              SaveWizard(
                                codiceMeccanico:
                                    codiceMeccanicoController.text.isEmpty
                                    ? null
                                    : codiceMeccanicoController.text,
                                fotoFile: _image != null
                                    ? File(_image!.path)
                                    : null,
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
