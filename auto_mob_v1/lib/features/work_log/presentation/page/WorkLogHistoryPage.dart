import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widget/WorkLogItemCard.dart';
import 'package:auto_mob_v1/core/widgets/Card/AmVehicleSelectableCard.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/AmPullDownLG.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../core/widgets/Buttons/SoftButton.dart';

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
  ScrollController? _scrollController;
  bool _showBadge = false;
  late final List<GlassMenuItem> items = [
    GlassMenuItem(
      title: "GOLF",
      onTap: () {},
      icon: Icon(CupertinoIcons.car_detailed),
    ),
    GlassMenuItem(
      title: "FIAT",
      onTap: () {},
      icon: Icon(CupertinoIcons.car_detailed),
    ),
    GlassMenuItem(
      title: "TOYOTA",
      onTap: () {},
      icon: Icon(CupertinoIcons.car_detailed),
    ),
  ];
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
        title: OCLiquidGlassGroup(
          settings: OCLiquidGlassSettings(
            refractStrength: -0.130,
            blurRadiusPx: 1.0,
            specStrength: 0,
            specWidth: 0.0,
            specAngle: 145,
            blendPx: 40,
            specPower: 40,
          ),
          // --- IL FIX È QUI ---
          // Aggiungiamo Padding per creare uno "spazio vitale" invisibile.
          // In questo modo il contenitore è più grande dei 45px del bottone,
          // e quando il bottone si espande a 50px non tocca i bordi tagliati.
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 4.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentGeometry.centerLeft,
                    child: AmPullDownLG(
                      brand: "alfa romeo",
                      onTap: () {},
                      lable: 'STELVIO',
                        larghezza: 200,
                    buttonIcons: Icons.directions_car,
                      buttonIconsSize: 26,
                      buttonIconColor: Colors.white,
                      buttonLableStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    color: Colors.white,
                    ),
                       arrow: true,
                      children: [ItemMorphPopUp(icon: CupertinoIcons.car_detailed, text: "STELVIO", onTap: (){},iconSize: 22,iconColor: const Color(0xFFFF6B00) , iconsWheight: FontWeight.w100,)]
                    ),
                  ),
                ),

                Expanded(
                  child: Align(
                    alignment: AlignmentGeometry.center,
                    child: OCLiquidGlass(
                      borderRadius: 100,
                      height: 45,
                      color: const Color(0xFF232326).withOpacity(0.5),
                      child: Center(
                        child: const Text(
                          "LAVORI",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentGeometry.centerRight,
                    child: AmSoftButton(
                      width: 45,
                      height: 45,
                      color: const Color(0xFFFF6B00),
                      icon: Icons.add,
                      onPressed: () {
                        context.push(
                          '/addFunctional',
                          extra: {
                            'type': EnumPopUp.altro,
                            'id': 'veicolo_id_mock',
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Corpo della pagina con Blur e Scroll
          SoftEdgeBlur(
            edges: [
              EdgeBlur(
                type: EdgeType.topEdge,
                size: 130,

                sigma: 10,
                controlPoints: [
                  ControlPoint(position: 0.3, type: ControlPointType.visible),
                  ControlPoint(
                    position: 1.0,
                    type: ControlPointType.transparent,
                  ),
                ],
              ),
              EdgeBlur(
                type: EdgeType.bottomEdge,
                size: 150,
                tintColor: Colors.black54,
                sigma: 10,
                controlPoints: [
                  ControlPoint(position: 0.3, type: ControlPointType.visible),
                  ControlPoint(
                    position: 1.0,
                    type: ControlPointType.transparent,
                  ),
                ],
              ),
            ],
            child: ListView(

              padding: const EdgeInsets.symmetric(horizontal: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header "Storico Lavori"
                Padding(padding: const EdgeInsets.only(top: 140.0)),

                const SizedBox(height: 32),

                // Selettore Veicoli (Orizzontale) - Ora parte del flusso di scroll




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
    );
  }
}
