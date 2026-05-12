import 'package:auto_mob_v1/core/widgets/Card/AmSparePartCard.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Midifyitem extends StatelessWidget {
  const Midifyitem({super.key});

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
  Widget build(BuildContext context) {
    return BlocBuilder<WorkLogBloc, WorkLogState>(
      builder: (context, state) {
        if (state.selectedParts.isEmpty) {
          return const Center(
            child: Text(
              "Nessun pezzo selezionato",
              style: TextStyle(color: Color(0xFF636366), fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 140, left: 20, right: 20, bottom: 100),
          itemCount: state.selectedParts.length,
          itemBuilder: (context, index) {
            final partId = state.selectedParts[index];
            final name = kParts[partId] ?? 'Unknown';
            return AmSparePartCard(
              id: partId,
              name: name,
              quantityNotifier: ValueNotifier<int>(1),
              isExpandedNotifier: ValueNotifier<bool>(false),
            );
          },
        );
      },
    );
  }
}
