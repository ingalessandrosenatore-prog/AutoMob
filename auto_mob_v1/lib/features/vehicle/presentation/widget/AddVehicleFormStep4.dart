import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/Buttons/backButton.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/Textfield.dart';
import 'MaintenanceSectionCard.dart';

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

class AddVehicleFormStep4 extends StatelessWidget {
  const AddVehicleFormStep4({super.key});

  @override
  Widget build(BuildContext context) {
    final revisioneDateController = TextEditingController();
    final ultimoCambioGommeController = TextEditingController();
    final prossimoCambioGommeController = TextEditingController();
    final ultimaInversioneController = TextEditingController();
    final prossimaInversioneController = TextEditingController();

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: Column(
              children: [
                SizedBox(height: 150),
                MaintenanceSectionCard(
                  icon: Icons.calendar_month,
                  title: "Revisione",
                  children: [
                    Row(
                      children: [
                        AmTextField(
                          label: "Prossima revisione",
                          placeholder: "gg/mm/aaaa",
                          controller: revisioneDateController,
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.datetime,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF48484A),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "FREQUENZA REVISIONE",
                        style: TextStyle(
                          color: Color(0xFF636366),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        QuickOptionChip(label: "Ogni anno"),
                        SizedBox(width: 10),
                        QuickOptionChip(label: "Ogni 2 anni"),
                        SizedBox(width: 10),
                        QuickOptionChip(label: "Ogni 4 anni"),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Sezione Cambio Gomme
                MaintenanceSectionCard(
                  icon: Icons.sync,
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
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "PROSSIMO CAMBIO",
                        style: TextStyle(
                          color: Color(0xFF48484A),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        QuickOptionChip(label: "5.000 km"),
                        SizedBox(width: 8),
                        QuickOptionChip(label: "10.000 km"),
                        SizedBox(width: 8),
                        QuickOptionChip(label: "15.000 km"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AmTextField(
                          label: "",
                          placeholder: "oppure inserisci km esatto",
                          controller: prossimoCambioGommeController,
                          isRequired: false,
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
                  ],
                ),

                const SizedBox(height: 20),

                // Sezione Inversione Gomme
                MaintenanceSectionCard(
                  icon: Icons.swap_horiz,
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
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        QuickOptionChip(label: "5.000 km"),
                        SizedBox(width: 8),
                        QuickOptionChip(label: "10.000 km"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        AmTextField(
                          label: "",
                          placeholder: "oppure inserisci km esatto",
                          controller: prossimaInversioneController,
                          isRequired: false,
                          obscureText: false,
                          keyboardType: TextInputType.number,
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(top: 14, right: 12),
                            child: Icon(
                              Icons.unfold_more,
                              color: Color(0xFF48484A),
                              size: 20,
                            ),
                          ),
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 15),
              child: Container(
                child: WizardHeader(
                  stepIcon: Icons.calendar_today_outlined,
                  stepNumber: 4,
                  totalSteps: 5,
                  title: "Scadenze",
                  onClose: () =>
                      context.pop('/home'),
                ),
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
                            Step4Submitted(
                              prossimarevisione: _parseDateStep4(
                                revisioneDateController.text,
                              ),
                              kmUltimoCambioGomme: int.tryParse(
                                ultimoCambioGommeController.text,
                              ),
                              kmProssimoCambioGomme: int.tryParse(
                                prossimoCambioGommeController.text,
                              ),
                              kmUltimaInversioneGomme: int.tryParse(
                                ultimaInversioneController.text,
                              ),
                              kmProssimaInversioneGomme: int.tryParse(
                                prossimaInversioneController.text,
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
          ),
        ),
      ],
    );
  }
}

class QuickOptionChip extends StatelessWidget {
  final String label;

  const QuickOptionChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
