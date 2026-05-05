import 'dart:ui';

import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
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

class AddVehicleFormStep2 extends StatefulWidget {
  const AddVehicleFormStep2({super.key});

  @override
  State<AddVehicleFormStep2> createState() => _AddVehicleFormStep2State();
}

class _AddVehicleFormStep2State extends State<AddVehicleFormStep2> {
  final IntervalloTagliandoController = TextEditingController();
  final kmTagliandoController = TextEditingController();
  final IntervalloDistribuzioneController = TextEditingController();
  final kmDistribuzioneController = TextEditingController();
  final   kmRichiamoTagliandoController = TextEditingController();
  String kmIntervalloTagInseriti = "0";
  String kmLAstTaglIns = "0";
  String kmLastDist = "0";
  String kmIntervallDistInseriti = "0";

  @override
  Widget build(BuildContext context) {


    return Stack(
      children: [
    Positioned.fill(
      child: SoftEdgeBlur(
        edges: [
      EdgeBlur(
      type: EdgeType.topEdge,
        size: 150,
        controlPoints: [
          ControlPoint(position: 0.7, type: ControlPointType.visible),
          ControlPoint(position: 1.0, type: ControlPointType.transparent),
        ],
        sigma: 10,
      ),
      EdgeBlur(
      type: EdgeType.bottomEdge,
      size: 150,
      controlPoints: [
      ControlPoint(position: 0.7, type: ControlPointType.visible),
      ControlPoint(position: 1.0, type: ControlPointType.transparent),
      ],
      sigma: 10,
      ),
      ],
        child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            child: Column(
              children: [

                Column(
                  children: [


                    // 1. Ultimo Tagliando
                    SizedBox(height: 150),
                    MaintenanceSectionCard(
                      icon: Icons.handyman,
                      title: "Ultimo tagliando",
                      children: [

                        Row(
                          children: [

                            const SizedBox(width: 16),
                            AmTextField(
                              label: "Km effettuato",
                              placeholder: "45000",
                              onChanged: (val) => setState(() {kmLAstTaglIns = val;}),
                              controller: kmTagliandoController,
                              isRequired: false,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Text("km", style: TextStyle(color: Color(0xFF48484A), fontWeight: FontWeight.bold)),
                              ),
                            ),
                            AmTextField(
                              label: "Intervallo di km ",
                              placeholder: "15000",
                              onChanged: (val) => setState(() {kmIntervalloTagInseriti=val;}),
                              controller: IntervalloTagliandoController,
                              isRequired: false,
                              obscureText: false,
                              keyboardType: TextInputType.datetime,
                              suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF48484A), size: 20),
                            ),
                          ],
                        ),

                        SizedBox(height: 10,),
                        Container(
                          color: Color(0xFF0F0F11).withOpacity(0.6),
                          child: Row(children: [
                            Text(
                              "Prossima sostituzione prevista a : ${(int.tryParse(kmLAstTaglIns) ?? 0) + (int.tryParse(kmIntervalloTagInseriti) ?? 0)} km",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],),
                        )

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

                          ],
                        ),
                        SizedBox(height: 10,),
                        Row(
                          children: [
                            AmTextField(
                              label: "effettuato a km ",
                              placeholder: "130000",
                              onChanged: (val){setState(() {
                                 kmLastDist=val;}); },
                              controller: kmDistribuzioneController,
                              isRequired: true,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Text("km", style: TextStyle(color: Color(0xFF48484A), fontWeight: FontWeight.bold)),
                              ),
                            ),
                            AmTextField(
                              label: "Sostituzione Prevista ogni ",
                              placeholder: "60000",
                              onChanged: (val) => setState(() {kmIntervallDistInseriti =  val;}),
                                controller:  IntervalloDistribuzioneController,
                              isRequired: false,
                              obscureText: false,
                              keyboardType: TextInputType.datetime,
                              suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF48484A), size: 20),
                            ),
                          ],
                        ),

                        SizedBox(height: 10,),
                        Row(
                          children: [
                            Text(
                              "Prossima sostituzione prevista a : ${(int.tryParse(kmLastDist) ?? 0) + (int.tryParse (kmIntervallDistInseriti) ?? 0)} km",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),


                            ),
                          ],
                        ),
                      ],
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
            stepNumber: 2,
            totalSteps: 5,
            title: "Storico manutenzioni",
            onClose: (){context.pop('/home');},
          ),
        ),

        Positioned(
          bottom:0,
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
                    onPressed: () => context.read<AddVehicleBloc>().add(StepBackPressed()),
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
                        Step2Submitted(
                          intervalloTagliando: int.tryParse(IntervalloTagliandoController.text),
                          kmUltimoTagliando: int.tryParse(kmTagliandoController.text),
                          intervalloUltimaDistribuzione: int.tryParse(IntervalloDistribuzioneController.text),
                          kmUltimaDistribuzione: int.tryParse(kmDistribuzioneController.text),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        )
      ]
    );
  }
}
