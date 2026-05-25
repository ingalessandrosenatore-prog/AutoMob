import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widget/WorkLogItemCard.dart';
import 'package:auto_mob_v1/core/widgets/Card/AmVehicleSelectableCard.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/AmVehicleFloatingBadge.dart';
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
  late bool isSelct1 = true;
  late bool isSelct2 = false;
   ScrollController ?_scrollController;
  bool _showBadge = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(() {
      if (_scrollController!.offset > 200 && !_showBadge) {
        setState(() => _showBadge = true);
      } else if (_scrollController!.offset <= 180 && _showBadge) {
        setState(() => _showBadge = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    const Color backgroundColor = Color(0xFF0F0F11);

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent.withOpacity(0),
        scrolledUnderElevation: 0,
        actions: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _showBadge ? 1.0 : 0.0,
            child: AmVehicleFloatingBadge(
              brand: "Volkswagen",
              model: "Golf",
              onTap: () {
                // Azione opzionale
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Corpo della pagina con Blur e Scroll
          SoftEdgeBlur(
            edges: [
              EdgeBlur(
                type: EdgeType.topEdge,
                size: 130,
                tintColor: Colors.black54,
                sigma: 10,
                controlPoints: [

                  ControlPoint(position: 0.3, type: ControlPointType.visible),
                  ControlPoint(position: 1.0, type: ControlPointType.transparent),
                ],
              ),
              EdgeBlur(
                type: EdgeType.bottomEdge,
                size: 150,
                tintColor: Colors.black87,
                sigma: 10,
                controlPoints: [
                  ControlPoint(position: 0.3, type: ControlPointType.visible),
                  ControlPoint(position: 1.0, type: ControlPointType.transparent),
                ],
              )
            ],
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header "Storico Lavori"
                Padding(
                  padding: const EdgeInsets.only(top: 140.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [


                      Container(
                        color: backgroundColor,
                        child: const Text(
                          " Storico Lavori",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Selettore Veicoli (Orizzontale) - Ora parte del flusso di scroll
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      AmVehicleSelectableCard(
                        brand: "Volkswagen",
                        model: "Golf",
                        plate: "AB 123 CD",
                        fuelType: "BEN",
                        isSelected: isSelct1,
                        onTap: () {
                          setState(() {
                            isSelct1 = !isSelct1;
                          });
                        },
                      ),
                      AmVehicleSelectableCard(
                        brand: "Toyota",
                        model: "Yaris",
                        plate: "EF 456 GH",
                        fuelType: "IBR",
                        isSelected: isSelct2,
                        onTap: () {
                          setState(() {
                            isSelct2 = !isSelct2;
                          });
                        },
                      ),
                      AmVehicleSelectableCard(
                        brand: "Fiat",
                        model: "Panda",
                        plate: "IL 789 MN",
                        fuelType: "BEN",
                        isSelected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Lista Interventi
                const WorkLogItemCard(
                  title: "Tagliando",
                  date: "12 Nov 2023",
                  km: "42.000 km",
                  description: "Olio 5W30 + filtri",
                  hasWorkshop: true,
                ),
                const WorkLogItemCard(
                  title: "Cambio gomme",
                  date: "03 Ott 2023",
                  km: "38.000 km",
                  description: "Invernali Pirelli",
                ),
                const WorkLogItemCard(
                  title: "Freni anteriori",
                  date: "20 Mag 2023",
                  km: "35.200 km",
                  description: "Dischi + pastiglie",
                  hasWorkshop: true,
                ),
                const WorkLogItemCard(
                  title: "Freni anteriori",
                  date: "20 Mag 2023",
                  km: "35.200 km",
                  description: "Dischi + pastiglie",
                  hasWorkshop: true,
                ),
                const WorkLogItemCard(
                  title: "Freni anteriori",
                  date: "20 Mag 2023",
                  km: "35.200 km",
                  description: "Dischi + pastiglie",
                  hasWorkshop: true,
                ),
                const WorkLogItemCard(
                  title: "Freni anteriori",
                  date: "20 Mag 2023",
                  km: "35.200 km",
                  description: "Dischi + pastiglie",
                  hasWorkshop: true,
                ),
                const WorkLogItemCard(
                  title: "Freni anteriori",
                  date: "20 Mag 2023",
                  km: "35.200 km",
                  description: "Dischi + pastiglie",
                  hasWorkshop: true,
                ),
                const SizedBox(height: 120), // Spazio extra per il FAB
              ],
            ),
          ),


        ],
      ),
      // 3. FAB Aggiungi
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.push('/addFunctional', extra: {
              'type': EnumPopUp.altro,
              'id': 'veicolo_id_mock',
            });
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
