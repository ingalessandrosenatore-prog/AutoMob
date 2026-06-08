import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/AmPullDownLG.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/SoftButton.dart';
import 'package:auto_mob_v1/core/widgets/Card/KpiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_pull_down_button.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../Bloc/dashboardBloc.dart';
import '../Bloc/dashboardEvent.dart';
import '../Bloc/dashboardState.dart';
import '../widget/CardAuto.dart';
import '../widget/CardOfficina.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => GetIt.I<DashboardBloc>()..add(LoadDashboardData()),
      child: const _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatefulWidget {
  const _HomeViewBody();
  @override
  State<_HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<_HomeViewBody> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C23),
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
            blendPx: 20,
            specPower: 10,
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
                      brand: '',
                      lable: '',
                      onTap: () {},
                      larghezza: 180,
                      buttonIcons: Icons.person,
                      buttonIconsSize: 26,
                      buttonIconColor: Colors.white,
                      buttonLableStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      arrow: false,
                      children: [
                        ItemMorphPopUp(
                          icon: Icons.logout,
                          text: "LOGOUT",
                          onTap: () {},
                          iconColor: Colors.white,
                          iconSize: 22,
                            iconsWheight: FontWeight.w400
                        ),
                        ItemMorphPopUp(
                          icon: Icons.settings_outlined,
                          text: "SETTINGS",
                          onTap: () {},
                          iconColor: Colors.white,
                          iconSize: 22,
                          iconsWheight: FontWeight.w400,

                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Align(
                    alignment: AlignmentGeometry.center,
                    child: OCLiquidGlass(
                      borderRadius: 100,
                      height: 45,
                      enabled: false,
                      color: const Color(0xFF232326).withOpacity(0.5),
                      child: Center(
                        child: const Text(
                          "VEICOLI",
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
                        // context.push('/addVeichle');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SoftEdgeBlur(
        edges: [
          EdgeBlur(
            type: EdgeType.topEdge,
            size: 120,
            tintColor: Colors.black54,
            sigma: 0,
            controlPoints: [
              ControlPoint(position: 0.1, type: ControlPointType.visible),
              ControlPoint(position: 0.6, type: ControlPointType.visible),
              ControlPoint(position: 1.0, type: ControlPointType.transparent),
            ],
          ),
          EdgeBlur(
            type: EdgeType.bottomEdge,
            size: 95,
            tintColor: Colors.black54,

            sigma:0,
            controlPoints: [
              ControlPoint(position: 0.5, type: ControlPointType.visible),
              ControlPoint(position: 1.0, type: ControlPointType.transparent),
            ],
          ),
        ],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),

              // lista auto
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading || state is DashboardInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is DashboardError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFFF453A)),
                        ),
                      ),
                    );
                  }
                  if (state is DashboardLoaded) {
                    final vehicles = state.vehicles;
                    return SizedBox(
                      height: 500, // Leggermente aumentato per sicurezza
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                scrollDirection: Axis.horizontal,
                                controller: _pageController,
                                onPageChanged: (index) {
                                  context.read<DashboardBloc>().add(
                                    DashboardPageChanged(index),
                                  );
                                },
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  final v = vehicles[index];
                                  return RepaintBoundary(
                                    child: CardAuto(
                                      marca: v.brand,
                                      modello: v.model,
                                      kmTotali: v.isPlaceholder
                                          ? '—'
                                          : '${v.kmCurrent} km',
                                      immaginePath: v.fotoPath,
                                      anno: v.year,
                                      nextRevisionDate: v.nextRevisionDate,
                                      onKmTap: v.isPlaceholder
                                          ? null
                                          : () => context.pushNamed(
                                              'updateKm',
                                              extra: {
                                                'currentKm': '${v.kmCurrent}',
                                              },
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSmoothIndicator(
                              activeIndex: state.index,
                              count: vehicles.length,
                              effect: const ExpandingDotsEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                expansionFactor: 2,
                                activeDotColor: Color(0xFFFF6B00),
                                dotColor: Color(0xFF2C2C35),
                                radius: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // lista kpi per il veicolo corrente
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: RepaintBoundary(
                  child: AmWorkshopCard(
                    nomeOfficina: 'Nessuna officina ',
                    codiceMeccanico: '—',
                    stato: '—',
                    colore: Color(0xFFFFB4AB),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(9.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "STATO VEICOLO",
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
                    Icon(Icons.car_crash_outlined, color: Color(0xFFFF6B00)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (BuildContext context, state) {
                    if (state is DashboardLoaded) {
                      final currentVehicle = state.vehicles[state.index];
                      if (currentVehicle.isPlaceholder) {
                        return const SizedBox.shrink();
                      }

                      final km = currentVehicle.kmCurrent;

                      // Tagliando
                      final currentKmAtServiceTag =
                          currentVehicle.lastTagliandoKm ?? km;
                      final nextServTag =
                          currentKmAtServiceTag +
                          currentVehicle.tagliandoIntervalKm;
                      final remainKmTag = nextServTag - km;
                      final percTag =
                          ((remainKmTag * 100) /
                                  currentVehicle.tagliandoIntervalKm)
                              .clamp(0.0, 100.0);

                      // Distribuzione — TODO: aggiungere distribuzioneIntervalKm all'entità Vehicle
                      const distribuzioneIntervalKm = 60000;
                      final currentKmAtServiceDist =
                          currentVehicle.lastDistribuzioneKm ?? km;
                      final nextServDist =
                          currentKmAtServiceDist + distribuzioneIntervalKm;
                      final remainKmDist = nextServDist - km;
                      final percDist =
                          ((remainKmDist * 100) / distribuzioneIntervalKm)
                              .clamp(0.0, 100.0);

                      // Cambio gomme
                      final currentKmAtServiceChangGom =
                          currentVehicle.lastTireChangeKm ?? km;
                      final nextServGomme =
                          currentKmAtServiceChangGom +
                          currentVehicle.tireChangeIntervalKm;
                      final remainKmGomme = nextServGomme - km;
                      final percGomme =
                          ((remainKmGomme * 100) /
                                  currentVehicle.tireChangeIntervalKm)
                              .clamp(0.0, 100.0);

                      // Inversione gomme
                      final currentKmAtServiceRotGom =
                          currentVehicle.lastTireRotationKm ?? km;
                      final nextServInv =
                          currentKmAtServiceRotGom +
                          currentVehicle.tireRotationIntervalKm;
                      final remainKmInv = nextServInv - km;
                      final percInv =
                          ((remainKmInv * 100) /
                                  currentVehicle.tireRotationIntervalKm)
                              .clamp(0.0, 100.0);

                      return Column(
                        children: [
                          RepaintBoundary(
                            child: AmMaintenanceKpiCard(
                              icon: Icons.handyman_outlined,
                              color: choseColor(percTag),
                              label: "tagliando",
                              remainingKm: remainKmTag,
                              percentage: percTag,
                              onTap: () => _pushFunctional(
                                context,
                                EnumPopUp.aggiornaTagliando,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: AmMaintenanceKpiCard(
                              icon: Icons.settings_outlined,
                              color: choseColor(percDist),
                              label: "distribuzione",
                              remainingKm: remainKmDist,
                              percentage: percDist,
                              onTap: () => _pushFunctional(
                                context,
                                EnumPopUp.aggiornaDistribuzione,
                              ),
                            ),
                          ),

                          RepaintBoundary(
                            child: AmMaintenanceKpiCard(
                              icon: Icons.tire_repair_outlined,
                              color: choseColor(percGomme),
                              label: "cambio gomme",
                              remainingKm: remainKmGomme,
                              percentage: percGomme,
                              onTap: () => _pushFunctional(
                                context,
                                EnumPopUp.aggiornaCambioGomme,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: AmMaintenanceKpiCard(
                              icon: Icons.sync_outlined,
                              color: choseColor(percInv),
                              label: "inversione gomme",
                              remainingKm: remainKmInv,
                              percentage: percInv,
                              onTap:
                                  () {}, // TODO: Implementa callback per inversione
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  void _pushFunctional(BuildContext context, EnumPopUp type) {
    final s = context.read<DashboardBloc>().state;
    if (s is DashboardLoaded) {
      context.push(
        '/addFunctional',
        extra: {'type': type, 'id': s.vehicles[s.index].id},
      );
    }
  }

  Color choseColor(double perc) {
    if (perc >= 75) {
      return const Color(0xFF3192F3);
    } else if (perc >= 50) {
      return const Color(0xFF7361AC);
    } else if (perc >= 25) {
      return const Color(0xFFFFB4AB);
    } else if (perc >= 5) {
      return const Color(0xFFFF6B00);
    } else if (perc >= 0) {
      return const Color(0xFFFF0000);
    } else {
      return const Color(0xFF721C24);
    }
  }
}
