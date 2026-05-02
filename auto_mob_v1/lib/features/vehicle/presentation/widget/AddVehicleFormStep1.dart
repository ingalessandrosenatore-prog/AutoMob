import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/DropDownReact.dart';
import '../../../../core/widgets/input/Textfield.dart';
import '../provider/add_vehicle_event.dart';

const List<String> kMarcheAuto = [
  'Abarth', 'Aiways', 'Alfa Romeo', 'Aston Martin', 'Audi',
  'Bentley', 'BMW', 'Bugatti', 'BYD',
  'Cadillac', 'Chevrolet', 'Chrysler', 'Citroën',
  'CUPRA',
  'Dacia', 'Dodge', 'DS Automobiles',
  'Ferrari', 'Fiat', 'Ford',
  'Genesis', 'GMC',
  'Great Wall', 'GWM ORA',
  'Honda', 'Hummer', 'Hyundai',
  'Jaguar', 'Jeep',
  'Kia',
  'Lamborghini', 'Lancia', 'Land Rover', 'Lexus', 'Lincoln', 'Lotus',
  'Maserati', 'Mazda', 'McLaren', 'Mercedes-Benz', 'MG', 'MINI',
  'Mitsubishi',
  'NIO', 'Nissan',
  'Oldsmobile', 'Opel',
  'Peugeot', 'Polestar', 'Pontiac', 'Porsche',
  'Ram', 'Renault', 'Rolls-Royce',
  'SEAT', 'Skoda', 'Smart', 'Subaru', 'Suzuki',
  'Tesla', 'Toyota',
  'Vauxhall', 'Volkswagen', 'Volvo',
  'Xpeng',
  'Zeekr',
];

final List<String> kAnniAuto = List.generate(
  2026 - 1900 + 1,
  (i) => (2026 - i).toString(),
);

const List<String> kTipiCarburante = [
  'Benzina',
  'Benzina + GPL',
  'Benzina + Metano',
  'Diesel',
  'Elettrico',
  'GPL',
  'Idrogeno',
  'Ibrido (Full Hybrid)',
  'Ibrido Mild (MHEV)',
  'Ibrido Plug-in (PHEV)',
  'Metano (CNG)',
  'Metano + Benzina',
];

class AddVehicleFormStep1 extends StatefulWidget {
  const AddVehicleFormStep1({super.key});


  @override
  State<AddVehicleFormStep1> createState() => _AddVehicleFormStep1State();
}

class _AddVehicleFormStep1State extends State<AddVehicleFormStep1> {
  String? carburante;
  String? marca;
  String? anno;
  final modelloController = TextEditingController();
  final targaController = TextEditingController();


  @override
  Widget build(BuildContext context) {


    return
        Stack(
          children : [
            Positioned(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                child: Column(
                  children: [
                    SizedBox(height: 150),
                    Row(
                      children: [
                        const SizedBox(height: 20),
                        AmDropdown<String>(
                          label: "Brand",
                          items: kMarcheAuto,
                          itemLabelBuilder: (item) => item,
                          value: marca,
                          onChanged: (val) { setState(() {;marca = val;}); },
                          placeholder: "Seleziona...",
                          isRequired: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Row(
                      children: [
                        const SizedBox(height: 20),
                        AmTextField(
                          label: "Modello",
                          placeholder: "es. Golf VIII",
                          controller: modelloController,
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Row(
                      children: [
                        const SizedBox(height: 20),
                        AmDropdown<String>(
                          label: "Anno",
                          items: kAnniAuto,
                          itemLabelBuilder: (item) => item,
                          value: anno,
                          onChanged: (val) { anno = val; },
                          placeholder: "Seleziona...",
                          isRequired: true,
                        ),
                        const SizedBox(width: 16),
                        AmDropdown<String>(
                          label: "Carburante",
                          items: kTipiCarburante,
                          value: carburante,
                          itemLabelBuilder: (item) => item,
                          onChanged: (val) { setState(() {
                            carburante = val;
                          }); },
                          placeholder: "Seleziona...",
                          isRequired: true,
                        ),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Row(
                      children: [

                        AmTextField(
                          label: "Targa",
                          placeholder: "AB 123 CD",
                          controller: targaController,
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),



                  ],
                ),
              ),
            ), Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: WizardHeader(
                stepIcon: Icons.directions_car,
                stepNumber: 1,
                totalSteps: 5,
                title: "Il tuo veicolo",
                onClose: () => Navigator.pop(context),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AmMainFab(
                label: "Continua",
                height: 60,
                width: 180,
                color: const Color(0xFFE85A1A),
                icon: Icons.chevron_right,
                onPressed: () {
                  if (marca == null || anno == null || carburante == null) return;
                  context.read<AddVehicleBloc>().add(
                    Step1Submitted(
                      marca: marca!,
                      modello: modelloController.text,
                      year: int.parse(anno!),
                      carburante: carburante!,
                      targa: targaController.text,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
         ]
                );
  }
}
