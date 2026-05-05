import 'package:auto_mob_v1/core/di/injection_container.dart';
import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/AmChoiceChip.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/backButton.dart';
import 'package:auto_mob_v1/core/widgets/input/DropDownReact.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/Textfield.dart';

/// Pop-up per aggiungere un nuovo intervento (WorkLog).
/// Segue lo stile di AddVehicleFormStep e le specifiche UI fornite.
class AddWorkLogPopUp extends StatelessWidget {
   late  EnumPopUp initialWorkType;
   final List<String> parts = [
     "Olio motore", "Filtro olio", "Filtro aria", "Filtro abitacolo",
     "Filtro carburante", "Pastiglie freni ant.", "Pastiglie freni post.",
     "Dischi freni ant.", "Dischi freni post.", "Liquido freni",
     "Liquido refrigerante", "Candele", "Cinghia distribuzione",
     "Tendicinghia", "Pompa acqua", "Batteria", "Spazzole tergi", "Ammortizzatori"
   ];

  AddWorkLogPopUp({super.key, required this.initialWorkType});

    int valore = 15000;
  final kmController = TextEditingController();
   final fateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    const Color backgroundColor = Color(0xFF0F0F11);

    return BlocProvider(
      create: (context) => sl<WorkLogBloc>(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // 1. Corpo Scorrevole
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 140, left: 20, right: 20, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TIPO INTERVENTO
                    Row(
                      children: [
                        BlocBuilder<WorkLogBloc, WorkLogState>(
                         builder: (context, state){
                            return  AmDropdown<EnumPopUp>(
                        label: "Tipo Intervento",
                        placeholder: "Seleziona...",
                        value: initialWorkType,
                        items: EnumPopUp.values,
                        itemLabelBuilder: (val) => val.name,
                        onChanged: (val) {

                          initialWorkType = val!;

                          context.read<WorkLogBloc>().add(
                            OnWorkTypeChange(type: initialWorkType)
                          );

                        },
                        );
                          }
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
      
                    // DATA E KM AL MOMENTO
                    Row(
                      children: [
                        AmTextField(
                          label: "Data",
                          placeholder: "gg/mm/aaaa",
                          controller: TextEditingController(),
                          isRequired: false,
                          obscureText: false,
                          keyboardType: TextInputType.datetime,
                          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF48484A), size: 18),
                        ),
                        const SizedBox(width: 16),
                        AmTextField(
                          label: "Km attuali ",
                          placeholder: "45230",
                          controller:  kmController ,
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
                    const SizedBox(height: 24),
      
                    // RICHIAMO TRA E PROSSIMO RICHIAMO (Card scura come in foto)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RICHIAMO TRA",
                        style: TextStyle(color: Color(0xFF636366), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          BlocBuilder<WorkLogBloc, WorkLogState>(
                              builder: (BuildContext context, state) {
                                return AmDropdown<int>(
                                  label: "",
                                  placeholder: "Seleziona...",
                                  value: valore,
                                  items: const [1000, 2000, 5000, 10000, 15000, 20000, 25000],
                                  itemLabelBuilder:(val) => val.toString(),
                                  onChanged: (v) {
                                    valore = v!;
                                    context.read<WorkLogBloc>().add(
                                        RichiamoChange(richiamoTra: int.tryParse(v.toString()) ?? 0)
                                    );
                                  },
                                );
                              }
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PROSSIMO RICHIAMO",
                                  style: TextStyle(color: Color(0xFF636366), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                BlocBuilder<WorkLogBloc, WorkLogState>(
                                    builder:  (BuildContext context, state){
                                      return  Container(
                                      height: 60,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F0F11),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE85A1A).withOpacity(0.3)),
                                      ),
                                      child: Text("${state.prosssimoRichiamo}km",
                                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                                    );
                                    }
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),




                    ],
                  ),
                ),
                    const SizedBox(height: 24),
      
                    BlocBuilder<WorkLogBloc, WorkLogState>(
                      builder: (BuildContext context, state) {
      
                        return ExpansionTile(
                          title: const Text("Seleziona pezzi di ricambio "),
                          subtitle: Text("Pezzi selezionati :"+ state.selectedParts.length.toString() ),
                          initiallyExpanded: false,
      
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 10,
                                children: parts.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final isSelected = state.selectedParts.contains(index);
                                  return AmChoiceChip(
                                    label: entry.value,
                                    isSelected: isSelected,
                                    onTap: () {
                                      context.read<WorkLogBloc>().add(
                                        WorkLogEventCohiceTap(isSelected: isSelected, id: index),
                                      );
                                    },
                                    id: index,
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
      
                      },
                    ),
                    // PEZZI DI RICAMBIO (Sezione espandibile)
      
                    const SizedBox(height: 24),
      
                    // NOTE
                    Row(
                      children: [
                        AmTextField(
                          label: "Note",
                          placeholder: "Dettagli aggiuntivi...",
                          controller: TextEditingController(),
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
      
                    // BANNER PREMIUM E FATTURA
                    _PremiumBanner(),
                  ],
                ),
              ),
            ),
      
            // 2. Intestazione Fissa (Header)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: backgroundColor,
                child: WizardHeader(
                  stepIcon: Icons.add_circle_outline,
                  stepNumber: 1, // Gestito come step singolo per ora
                  totalSteps: 1,
                  title: "Aggiungi intervento",
                  onClose: () {},
                ),
              ),
            ),
            Positioned(
              bottom: 0,
                left: 0,
                right: 0,
                child: AmOutlinedButton(
                  label: 'Salva',
                  color: Color(0x4A90E2FF),
                  onPressed: () {  },
                )
            )
          ],
        ),
      ),
    );
  }
}

/// Sezione interna per il richiamo manutenzione


/// Sezione per i pezzi di ricambio con ChoiceChips
class _SparePartsSection extends StatelessWidget {
  const _SparePartsSection();

  @override
  Widget build(BuildContext context) {
    final List<String> parts = [
      "Olio motore", "Filtro olio", "Filtro aria", "Filtro abitacolo",
      "Filtro carburante", "Pastiglie freni ant.", "Pastiglie freni post.",
      "Dischi freni ant.", "Dischi freni post.", "Liquido freni",
      "Liquido refrigerante", "Candele", "Cinghia distribuzione",
      "Tendicinghia", "Pompa acqua", "Batteria", "Spazzole tergi", "Ammortizzatori"
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pezzi di ricambio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("3 selezionati", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const Icon(Icons.keyboard_arrow_up, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: parts.map((part) {
              final isSelected = part.contains("Pastiglie") || part.contains("Dischi freni ant.");
              return AmChoiceChip(
                label: part,
                isSelected: isSelected,
                onTap: () {},
                activeColor: const Color(0xFFE85A1A),
                id: 3,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Widget per il banner Premium in fondo
class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              const Text("PREMIUM", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "· il costo di un paio di caffè per sbloccare la funzionalità",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("Sblocca", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("FATTURA", style: TextStyle(color: Color(0xFF636366), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F11),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
