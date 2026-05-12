import 'package:auto_mob_v1/core/di/injection_container.dart';
import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/AmChoiceChip.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/FabPrinc.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/backButton.dart';
import 'package:auto_mob_v1/core/widgets/input/DropDownReact.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_state.dart';
import 'package:auto_mob_v1/features/work_log/presentation/page/MidifyItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import '../../../../core/widgets/Card/PupUpHeadCard.dart';
import '../../../../core/widgets/input/Textfield.dart';

class AddWorkLogPopUp extends StatefulWidget {
  final EnumPopUp initialWorkType;
  final String id;

  const AddWorkLogPopUp({
    super.key,
    required this.initialWorkType,
    required this.id,
  });

  @override
  State<AddWorkLogPopUp> createState() => _AddWorkLogPopUpState();
}

class _AddWorkLogPopUpState extends State<AddWorkLogPopUp> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFF0F0F11);

    return BlocProvider(
      create: (context) => sl<WorkLogBloc>(),


        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              minHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Stack(
              children: [
              Positioned.fill(
                top: 0,
                right: 0,
                left: 0,
                child: SoftEdgeBlur(
                  edges: [
                    EdgeBlur(
                      type: EdgeType.topEdge,
                      size: 180,
                    tintColor: Colors.black87.withOpacity(0.6),
                      controlPoints: [
                        ControlPoint(position: 0.4, type: ControlPointType.visible),
                        ControlPoint(position: 1.0, type: ControlPointType.transparent),
                      ],
                      sigma: 30,
                    ),
                    EdgeBlur(
                      type: EdgeType.bottomEdge,
                      size: 150,
                      tintColor: Colors.black87.withOpacity(0.8),
                      controlPoints: [
                        ControlPoint(position: 0.3, type: ControlPointType.visible),
                        ControlPoint(position: 1.0, type: ControlPointType.transparent),
                      ],
                      sigma: 30,
                    ),
                  ],

                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    FirstPageAddWork(initialWorkType: widget.initialWorkType),
                    const Midifyitem(),
                  ],
                ),
              ),
              ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: WizardHeader(
                      stepIcon: Icons.add_circle_outline,
                      stepNumber: _currentPage + 1,
                      totalSteps: 2,
                      title: "Aggiungi intervento",
                      onClose: () => context.pop('/home'),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bottone INDIETRO con animazione di comparsa/scomparsa laterale e opacità

                           AnimatedContainer(
                             duration: const Duration(milliseconds: 300,),
                             curve: Curves.easeInOut,
                             width: _currentPage > 0 ? 120 : 0,
                             height: _currentPage > 0 ? 60 : 0,
                             child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                               curve:  Curves.ease,
                              opacity: _currentPage > 0 ? 1.0 : 0.0,
                              child: AmOutlinedButton(
                                label: 'INDIETRO',
                                color: const Color(0xFFE85A1A),
                                onPressed: _goToPreviousPage,
                              ),
                                                       ),
                           ),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear,
                          width: _currentPage > 0 ? 16 : 0,
                        ),
                        AnimatedScale(
                          curve: Curves.linear,
                          scale: _currentPage == 0 ? 1.0 : 0.92,
                          duration: const Duration(milliseconds: 300),
                          child: AmMainFab(
                            label: _currentPage == 0 ? 'CONTINUA' : 'SALVA',
                            color: _currentPage == 0 ? const Color(0x7E90E2FF) : const Color(0x4A90E2FF),
                            onPressed: _currentPage == 0 ? _goToNextPage : () {},
                            icon:  _currentPage == 0 ? Icons.arrow_forward_ios_outlined : Icons.add_task,
                            width: 260,
                            height: 65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        );

  }
}

class FirstPageAddWork extends StatefulWidget {
  final EnumPopUp initialWorkType;

  const FirstPageAddWork({super.key, required this.initialWorkType});

  @override
  State<FirstPageAddWork> createState() => _FirstPageAddWorkState();
}

class _FirstPageAddWorkState extends State<FirstPageAddWork> {
  late EnumPopUp _selectedWorkType;
  int _valore = 0;
  final _kmController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();

  static const Map<int, String> kParts = {
    1: 'Motore',
    2: 'Pistoni',
    3: 'Bielle',
    4: 'Albero motore',
    5: 'Testata',
    6: 'Guarnizione testata',
    7: 'Candele',
    8: 'Candelette',
    9: 'Cinghia distribuzione',
    10: 'Catena distribuzione',
    11: 'Tendicinghia',
    12: 'Pompa olio',
    13: 'Coppa olio',
    14: 'Valvole',
    15: 'Filtro olio',
    16: 'Filtro aria',
    17: 'Filtro abitacolo',
    18: 'Filtro carburante',
    19: 'Filtro gasolio',
    20: 'Pastiglie freno anteriori',
    21: 'Pastiglie freno posteriori',
    22: 'Dischi freno anteriori',
    23: 'Dischi freno posteriori',
    24: 'Tamburi freno',
    25: 'Ceppi freno',
    26: 'Liquido freni',
    27: 'Pompa freno',
    28: 'Ammortizzatori anteriori',
    29: 'Ammortizzatori posteriori',
    30: 'Molle anteriori',
    31: 'Molle posteriori',
    32: 'Silent block',
    33: 'Bracci sospensione',
    34: 'Tiranti sterzo',
    35: 'Scatola sterzo',
    36: 'Cambio',
    37: 'Frizione',
    38: 'Disco frizione',
    39: 'Volano',
    40: 'Cinghia trasmissione',
    41: 'Variatore',
    42: 'Giunto cardanico',
    43: 'Semiassi',
    44: 'Cuscinetti ruota',
    45: 'Marmitta',
    46: 'Catalizzatore',
    47: 'Collettore scarico',
    48: 'Silenziatore',
    49: 'Tubo di scarico',
    50: 'Sonda lambda',
    51: 'Alternatore',
    52: 'Motorino avviamento',
    53: 'Batteria',
    54: 'Bobina accensione',
    55: 'Centralina',
    56: 'Regolatore di tensione',
    57: 'Relay',
    58: 'Fusibili',
    59: 'Faro anteriore sinistro',
    60: 'Faro anteriore destro',
    61: 'Luce posteriore sinistra',
    62: 'Luce posteriore destra',
    63: 'Luce posizione anteriore sinistra',
    64: 'Luce posizione anteriore destra',
    65: 'Luce posizione posteriore sinistra',
    66: 'Luce posizione posteriore destra',
    67: 'Lampada targa',
    68: 'Luce freno',
    69: 'Freccia anteriore sinistra',
    70: 'Freccia anteriore destra',
    71: 'Freccia posteriore sinistra',
    72: 'Freccia posteriore destra',
    73: 'Radiatore',
    74: 'Pompa acqua',
    75: 'Termostato',
    76: 'Vaschetta espansione',
    77: 'Ventola raffreddamento',
    78: 'Liquido raffreddamento',
    79: 'Manicotti raffreddamento',
    80: 'Serbatoio carburante',
    81: 'Pompa carburante',
    82: 'Iniettori',
    83: 'Carburatore',
    84: 'Corpo farfallato',
    85: 'Tubo carburante',
    86: 'Pneumatici',
    87: 'Cerchi',
    88: 'Valvole pneumatici',
    89: 'Cintura di sicurezza',
    90: 'Parabrezza',
    91: 'Tergicristalli',
    92: 'Pompa tergicristalli',
    93: 'Specchietto sinistro',
    94: 'Specchietto destro',
    95: 'Altro',
  };

  @override
  void initState() {
    super.initState();
    _selectedWorkType = widget.initialWorkType;
  }

  @override
  void dispose() {
    _kmController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: 150,),
        Row(
        children: [
          BlocBuilder<WorkLogBloc, WorkLogState>(
            builder: (context, state) {
              return AmDropdown<EnumPopUp>(
                label: "Tipo Intervento",
                placeholder: "Seleziona...",
                value: _selectedWorkType,
                items: EnumPopUp.values,
                itemLabelBuilder: (val) => val.name,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedWorkType = val);
                  context.read<WorkLogBloc>().add(OnWorkTypeChange(type: val));
                },
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 24),

      Row(
        children: [
          AmTextField(
            label: "Data",
            placeholder: "gg/mm/aaaa",
            controller: _dateController,
            isRequired: false,
            obscureText: false,
            keyboardType: TextInputType.datetime,
            suffixIcon: const Icon(
              Icons.calendar_today,
              color: Color(0xFF48484A),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          AmTextField(
            label: "Km attuali",
            placeholder: "45230",
            controller: _kmController,
            isRequired: true,
            obscureText: false,
            onChanged: (_) {
              context.read<WorkLogBloc>().add(
                CurrentKmChange(currentKm: int.tryParse(_kmController.text) ?? 0),
              );
            },
            keyboardType: TextInputType.number,
            suffixIcon: const Padding(
              padding: EdgeInsets.only(top: 14),
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
      const SizedBox(height: 24),

      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                BlocBuilder<WorkLogBloc, WorkLogState>(
                  builder: (context, state) {
                    return AmDropdown<int>(
                      label: "Richiamo tra",
                      placeholder: "Seleziona...",
                      value: _valore,
                      items: const [0, 1000, 2000, 5000, 10000, 15000, 20000, 25000],
                      itemLabelBuilder: (val) => val.toString(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _valore = v);
                        context.read<WorkLogBloc>().add(
                          RichiamoChange(intervallKM: v),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PROSSIMO RICHIAMO",
                        style: TextStyle(
                          color: Color(0xFF636366),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BlocBuilder<WorkLogBloc, WorkLogState>(
                        builder: (context, state) {
                          return Container(
                            height: 60,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F11),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE85A1A).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              "${state.prosssimoRichiamo}km",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
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
        builder: (context, state) {
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              title: const Text(
                "SELEZIONA PEZZI DI RICAMBIO",
                style: TextStyle(
                  color: Color(0xFF636366),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "PEZZI SELEZIONATI: ${state.selectedParts.length}",
                style: const TextStyle(
                  color: Color(0xFF636366),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              initiallyExpanded: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              collapsedBackgroundColor: const Color(0xFF151517),
              backgroundColor: const Color(0xFF29292B),
              textColor: const Color(0xFF636366),
              iconColor: const Color(0xFF636366),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: kParts.entries.map((entry) {
                      final partId = entry.key;
                      final isSelected = state.selectedParts.contains(partId);
                      return AmChoiceChip(
                        label: entry.value,
                        isSelected: isSelected,
                        onTap: () {
                          context.read<WorkLogBloc>().add(
                            WorkLogEventCohiceTap(isSelected: isSelected, id: partId),
                          );
                        },
                        id: partId,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 24),

      AmTextField(
        label: "Note",
        placeholder: "Dettagli aggiuntivi...",
        controller: _noteController,
        isRequired: false,
        obscureText: false,
        keyboardType: TextInputType.multiline,
      ),
      const SizedBox(height: 24),
    ]
    );
  }
}
