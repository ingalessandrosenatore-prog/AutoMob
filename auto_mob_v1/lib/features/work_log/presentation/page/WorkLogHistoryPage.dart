import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widget/FunctionalPopUp.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widget/WorkLogItemCard.dart';
import 'package:auto_mob_v1/core/widgets/Card/AmVehicleSelectableCard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

/// Pagina dello storico lavori (WorkLog).
/// Visualizza i veicoli selezionabili e la cronologia degli interventi.
class WorkLogHistoryPage extends StatefulWidget {
  const WorkLogHistoryPage({super.key});

  @override
  State<WorkLogHistoryPage> createState() => _WorkLogHistoryPageState();
}

class _WorkLogHistoryPageState extends State<WorkLogHistoryPage> {
  late bool isSelct1=true;
  late bool isSelct2=false;
  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    const Color backgroundColor = Color(0xFF0F0F11);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SoftEdgeBlur(
        edges: [
          EdgeBlur(type: EdgeType.topEdge,
              size: 140,
              tintColor: Colors.black54,
              sigma: 10, controlPoints:[
                ControlPoint(position: 0.1, type: ControlPointType.visible),
                ControlPoint(position: 0.6, type: ControlPointType.visible),
                ControlPoint(position: 1.0, type: ControlPointType.transparent),
              ]
          ),
          EdgeBlur(type: EdgeType.bottomEdge,
              size: 150,
              tintColor: Colors.black87,
              sigma: 10, controlPoints:[
                ControlPoint(position: 0.3, type: ControlPointType.visible),
                ControlPoint(position: 1.0, type: ControlPointType.transparent),
              ]
          )
        ],
        child:SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Storico",
                    style: TextStyle(
                      color: Color(0xFF636366),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Lavori",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Selettore Veicoli (Orizzontale)
            //TODO: implementare la selezione del veicolo
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  AmVehicleSelectableCard(
                    brand: "Volkswagen",
                    model: "Golf",
                    plate: "AB 123 CD",
                    fuelType: "BEN",
                    isSelected: isSelct1,
                    onTap: () {setState(() {
                      isSelct1 = !isSelct1;
                    });},
                  ),
                  AmVehicleSelectableCard(
                    brand: "Toyota",
                    model: "Yaris",
                    plate: "EF 456 GH",
                    fuelType: "IBR",
                    isSelected: isSelct2,
                    onTap: () {setState(() {
                      isSelct2=! isSelct2;
                    });},
                  ),
                  AmVehicleSelectableCard(
                    brand: "Fiat",
                    model: "Panda",
                    plate: "IL 789 MN",
                    fuelType: "BEN",
                    isSelected: false,
                    onTap: () { },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. Lista Interventi (Verticale)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: const [
                  WorkLogItemCard(
                    title: "Tagliando",
                    date: "12 Nov 2023",
                    km: "42.000 km",
                    description: "Olio 5W30 + filtri",
                    hasWorkshop: true,
                  ),
                  WorkLogItemCard(
                    title: "Cambio gomme",
                    date: "03 Ott 2023",
                    km: "38.000 km",
                    description: "Invernali Pirelli",
                  ),
                  WorkLogItemCard(
                    title: "Freni anteriori",
                    date: "20 Mag 2023",
                    km: "35.200 km",
                    description: "Dischi + pastiglie",
                    hasWorkshop: true,
                  ),
                  WorkLogItemCard(
                    title: "Freni anteriori",
                    date: "20 Mag 2023",
                    km: "35.200 km",
                    description: "Dischi + pastiglie",
                    hasWorkshop: true,
                  ),  WorkLogItemCard(
                    title: "Freni anteriori",
                    date: "20 Mag 2023",
                    km: "35.200 km",
                    description: "Dischi + pastiglie",
                    hasWorkshop: true,
                  ),  WorkLogItemCard(
                    title: "Freni anteriori",
                    date: "20 Mag 2023",
                    km: "35.200 km",
                    description: "Dischi + pastiglie",
                    hasWorkshop: true,
                  ),  WorkLogItemCard(
                    title: "Freni anteriori",
                    date: "20 Mag 2023",
                    km: "35.200 km",
                    description: "Dischi + pastiglie",
                    hasWorkshop: true,
                  ),
                  SizedBox(height: 100), // Spazio per non coprire l'ultimo elemento col FAB
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      // 4. FAB Aggiungi
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
        onPressed: () {
          // Navigazione verso il pop-up funzionale
          context.push(''); // Da recuperare dallo stato);
        },
        backgroundColor: orangeColor,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: const Text(
          "Aggiungi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.build_outlined, size: 20),
        ),
      ),
    );
  }
}
