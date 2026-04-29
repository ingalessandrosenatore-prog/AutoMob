import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/Buttons/backButton.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/Textfield.dart';
import 'MaintenanceSectionCard.dart';

DateTime? _parseDate(String text) {
  if (text.isEmpty) return null;
  final parts = text.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

class AddVehicleFormStep2 extends StatelessWidget {
  const AddVehicleFormStep2({super.key});

  @override
  Widget build(BuildContext context) {
    final dataTagliandoController = TextEditingController();
    final kmTagliandoController = TextEditingController();
    final dataDistribuzioneController = TextEditingController();
    final kmDistribuzioneController = TextEditingController();

    return Column(
      children: [
        WizardHeader(
          stepIcon: Icons.build,
          stepNumber: 2,
          totalSteps: 5,
          title: "Storico manutenzioni",
          onClose: () => context.read<AddVehicleBloc>().add(StepBackPressed()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // 1. Ultimo Tagliando
              MaintenanceSectionCard(
                icon: Icons.handyman,
                title: "Ultimo tagliando",
                children: [
                  Row(
                    children: [
                      AmTextField(
                        label: "Data",
                        placeholder: "gg/mm/aaaa",
                        controller: dataTagliandoController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.datetime,
                        suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF48484A), size: 20),
                      ),
                      const SizedBox(width: 16),
                      AmTextField(
                        label: "Km effettuato",
                        placeholder: "45000",
                        controller: kmTagliandoController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text("km", style: TextStyle(color: Color(0xFF48484A), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
                        label: "Data ultima sostituzione",
                        placeholder: "gg/mm/aaaa",
                        controller: dataDistribuzioneController,
                        isRequired: false,
                        obscureText: false,
                        keyboardType: TextInputType.datetime,
                        suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF48484A), size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      AmTextField(
                        label: "Prossimo richiamo (km)",
                        placeholder: "130000",
                        controller: kmDistribuzioneController,
                        isRequired: true,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Text("km", style: TextStyle(color: Color(0xFF48484A), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Km previsti per la sostituzione",
                      style: TextStyle(
                        color: Color(0xFF636366),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
                      label: "Continua",
                      color: const Color(0xFFE85A1A),
                      icon: Icons.chevron_right,
                      onPressed: () {
                        context.read<AddVehicleBloc>().add(
                          Step2Submitted(
                            dataUltimoTagliando: _parseDate(dataTagliandoController.text),
                            kmUltimoTagliando: int.tryParse(kmTagliandoController.text),
                            dataUltimaDistribuzione: _parseDate(dataDistribuzioneController.text),
                            kmUltimaDistribuzione: int.tryParse(kmDistribuzioneController.text),
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
      ],
    );
  }
}
