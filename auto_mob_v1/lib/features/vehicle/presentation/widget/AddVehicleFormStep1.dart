import 'package:auto_mob_v1/features/vehicle/presentation/provider/add_vehicle_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/Blur/AmEdgeBlur.dart';
import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/DropDownSearch.dart';
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

  // True dopo il primo "Continua": abilita gli errori dei campi obbligatori.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill dal draft: tornando indietro ritrovo i dati gia' inseriti.
    final d = context.read<AddVehicleBloc>().state.draft;
    marca = d.marca;
    anno = d.anno?.toString();
    carburante = d.carburante;
    if (d.modello != null) modelloController.text = d.modello!;
    if (d.targa != null) targaController.text = d.targa!;
  }

  @override
  void dispose() {
    modelloController.dispose();
    targaController.dispose();
    super.dispose();
  }

  String? _requiredText(TextEditingController c) {
    if (_submitted && c.text.trim().isEmpty) return 'Campo obbligatorio';
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
                  Row(
                    children: [
                      AmDropdownSearch<String>(
                        label: "Brand",
                        items: kMarcheAuto,
                        itemLabelBuilder: (item) => item,
                        value: marca,
                        onChanged: (val) => setState(() => marca = val),
                        placeholder: "Seleziona...",
                        isRequired: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AmTextField(
                        label: "Modello",
                        placeholder: "es. Golf VIII",
                        controller: modelloController,
                        isRequired: true,
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                        errorText: _requiredText(modelloController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AmDropdownSearch<String>(
                        label: "Anno",
                        items: kAnniAuto,
                        itemLabelBuilder: (item) => item,
                        value: anno,
                        onChanged: (val) => setState(() => anno = val),
                        placeholder: "Seleziona...",
                        isRequired: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AmDropdownSearch<String>(
                        label: "Carburante",
                        items: kTipiCarburante,
                        value: carburante,
                        itemLabelBuilder: (item) => item,
                        onChanged: (val) => setState(() => carburante = val),
                        placeholder: "Seleziona...",
                        isRequired: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AmTextField(
                        label: "Targa",
                        placeholder: "AB 123 CD",
                        controller: targaController,
                        isRequired: true,
                        obscureText: false,
                        keyboardType: TextInputType.text,
                        onChanged: (_) => setState(() {}),
                        errorText: _requiredText(targaController),
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
          right: 0,
          left: 0,
          child: WizardHeader(
            stepIcon: Icons.directions_car,
            stepNumber: 1,
            totalSteps: 5,
            title: "Il tuo veicolo",
            onClose: () => context.pop('/home'),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: AmMainFab(
              label: "Continua",
              height: 60,
              width: 180,
              color: const Color(0xFFE85A1A),
              icon: Icons.chevron_right,
              onPressed: () {
                setState(() => _submitted = true);
                // Controllo i campi obbligatori; se ne manca uno, avviso e non avanzo.
                final mancanti = <String>[
                  if (marca == null) 'Brand',
                  if (modelloController.text.trim().isEmpty) 'Modello',
                  if (anno == null) 'Anno',
                  if (carburante == null) 'Carburante',
                  if (targaController.text.trim().isEmpty) 'Targa',
                ];
                if (mancanti.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFFF453A),
                      content: Text(
                        'Compila i campi obbligatori: ${mancanti.join(', ')}',
                      ),
                    ),
                  );
                  return;
                }
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
        ),
      ],
    );
  }
}
