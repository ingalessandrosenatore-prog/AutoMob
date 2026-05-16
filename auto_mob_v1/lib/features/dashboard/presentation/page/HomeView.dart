import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/AmFabActionRounded.dart';
import 'package:auto_mob_v1/core/widgets/Buttons/SoftButton.dart';
import 'package:auto_mob_v1/core/widgets/Card/KpiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../Bloc/dashboardBloc.dart';
import '../Bloc/dashboardEvent.dart';
import '../Bloc/dashboardState.dart' ;
import '../widget/CardAuto.dart';
import '../widget/CardOfficina.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => GetIt.I<DashboardBloc>()..add(LoadDashboardData()),
      child:  _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatelessWidget {

   _HomeViewBody();

  @override
  Widget build(BuildContext context) {
    final controller = PageController();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C23),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent.withOpacity(0),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          AmSoftButton(
            label: 'AGGIUNGI',
            width: 140,
            height: 45,
            color: const Color.fromRGBO(232, 90, 26, 1),
            icon: Icons.add,
            onPressed: () => context.pushNamed('aggiungi_veicolo'),
          ),
        ],
      ),
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
              size: 50,
              tintColor: Colors.black54,
              sigma: 10, controlPoints:[
                ControlPoint(position: 0.3, type: ControlPointType.visible),
                ControlPoint(position: 1.0, type: ControlPointType.transparent),
              ]
          )
        ],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.all(9.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Container(
                      color: Color(0xFF1A1C23), // Rosso solido, no opacità
                      child: Text(
                        "I MIEI VEICOLI",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2)
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
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
                      height: 280,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                scrollDirection: Axis.horizontal,
                                controller: controller,
                                onPageChanged: (index) {
                                  context.read<DashboardBloc>().add(DashboardPageChanged(index));
                                },
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  final v = vehicles[index];
                                  return CardAuto(
                                    marca: v.brand,
                                    modello: v.model,
                                    kmTotali: v.isPlaceholder ? '—' : '${v.kmCurrent} km',
                                    immaginePath: v.fotoPath,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSmoothIndicator(
                              activeIndex: state.index,
                              count: vehicles.length,
                              effect: const   ExpandingDotsEffect(
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: AmWorkshopCard(nomeOfficina: 'Nessuna officina ', codiceMeccanico: '—', stato: '—', colore:Color(0xFFFFB4AB),),
              ),

              Padding(
                padding: const EdgeInsets.all(9.0) ,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "STATO VEICOLO",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2)
                        ],
                      ),
                    ),
                   Icon(Icons.car_crash_outlined,color:Color(0xFFFF6B00) ,),
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
                      final currentKmAtServiceTag = currentVehicle.lastTagliandoKm ?? km;
                      final nextServTag = currentKmAtServiceTag + currentVehicle.tagliandoIntervalKm;
                      final remainKmTag = nextServTag - km;
                      final percTag = ((remainKmTag * 100) / currentVehicle.tagliandoIntervalKm).clamp(0.0, 100.0);

                      // Distribuzione — TODO: aggiungere distribuzioneIntervalKm all'entità Vehicle
                      const distribuzioneIntervalKm = 60000;
                      final currentKmAtServiceDist = currentVehicle.lastDistribuzioneKm ?? km;
                      final nextServDist = currentKmAtServiceDist + distribuzioneIntervalKm;
                      final remainKmDist = nextServDist - km;
                      final percDist = ((remainKmDist * 100) / distribuzioneIntervalKm).clamp(0.0, 100.0);

                      // Cambio gomme
                      final currentKmAtServiceChangGom = currentVehicle.lastTireChangeKm ?? km;
                      final nextServGomme = currentKmAtServiceChangGom + currentVehicle.tireChangeIntervalKm;
                      final remainKmGomme = nextServGomme - km;
                      final percGomme = ((remainKmGomme * 100) / currentVehicle.tireChangeIntervalKm).clamp(0.0, 100.0);

                      // Inversione gomme
                      final currentKmAtServiceRotGom = currentVehicle.lastTireRotationKm ?? km;
                      final nextServInv = currentKmAtServiceRotGom + currentVehicle.tireRotationIntervalKm;
                      final remainKmInv = nextServInv - km;
                      final percInv = ((remainKmInv * 100) / currentVehicle.tireRotationIntervalKm).clamp(0.0, 100.0);

                      return Column(
                        children: [
                          AmMaintenanceKpiCard(icon: Icons.handyman_outlined, color: choseColor(percTag), label: "tagliando", remainingKm: remainKmTag, nextServiceKm: nextServTag, percentage: percTag),
                          AmMaintenanceKpiCard(icon: Icons.settings_outlined, color: choseColor(percDist), label: "distribuzione", remainingKm: remainKmDist, nextServiceKm: nextServDist, percentage: percDist),
                          AmMaintenanceKpiCard(icon: Icons.tire_repair_outlined, color: choseColor(percGomme), label: "cambio gomme", remainingKm: remainKmGomme, nextServiceKm: nextServGomme, percentage: percGomme),
                          AmMaintenanceKpiCard(icon: Icons.sync_outlined, color: choseColor(percInv), label: "inversione gomme", remainingKm: remainKmInv, nextServiceKm: nextServInv, percentage: percInv),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
          type:ExpandableFabType.up,
          distance: 70,
          duration: const Duration(milliseconds: 350),
        overlayStyle: ExpandableFabOverlayStyle(
          color: Colors.transparent,
          blur: 60,
        ),
        openButtonBuilder: RotateFloatingActionButtonBuilder(
            backgroundColor: const Color(0xFF1A1C23), // Sfondo scuro come in foto
            foregroundColor: const Color(0xFF8BA2D4), // Colore icona bluastro
            shape: const CircleBorder(),
            child: Icon(
              Icons.add,
              size: 28,
              shadows: [
                Shadow(
                  color: const Color(0xFF8BA2D4).withOpacity(0.8),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        closeButtonBuilder: FloatingActionButtonBuilder(
            size: 56,
            builder: (context, onPressed, progress) => FloatingActionButton(
              onPressed: onPressed,
              backgroundColor: const Color(0xFF1A1C23),
              foregroundColor: const Color(0xFFFF6B00),
              shape: const CircleBorder(),
              child: Icon(
                Icons.close,
                size: 25,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFF6B00).withOpacity(0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          children: [
            AmFabAction(
              color: Color(0xFFFF6B00),
              label: "AGGIORNA KM",
              icon: Icons.speed_outlined,
              onPressed: () {
                final s = context.read<DashboardBloc>().state;
                context.push('/updatePopUp', extra: {'currentKm': s is DashboardLoaded ? s.vehicles[s.index].kmCurrent.toString() : '0'});
              },
            ),
            AmFabAction(color: Color(0xFF3192F3), icon: Icons.trip_origin_outlined, label: "GOMME", onPressed: () => _pushFunctional(context, EnumPopUp.aggiornaCambioGomme)),
            AmFabAction(color:Color(0xFF7361AC), icon: Icons.build, label: "TAGLIANDO", onPressed: () => _pushFunctional(context, EnumPopUp.aggiornaTagliando)),
            AmFabAction(color: Color(0xFF7361AC), label:"DISTRIBUZIONE", icon: Icons.settings_input_component, onPressed: () => _pushFunctional(context, EnumPopUp.aggiornaDistribuzione)),
            AmFabAction(color: Color(0xFFFFB4AB) , icon: Icons.calendar_today_outlined, label:"REVSIONE", onPressed:  (){}),
      ],
      ),
    );

  }

  void _pushFunctional(BuildContext context, EnumPopUp type) {
    final s = context.read<DashboardBloc>().state;
    if (s is DashboardLoaded) {
      context.push('/addFunctional', extra: {
        'type': type,
        'id': s.vehicles[s.index].id,
      });
      print(s.vehicles[s.index].id);
    }
  }

  Color choseColor(double perc) {
    if (perc >= 75) {
      return const Color(0xFF3192F3);
    } else if (perc >= 50) {
      return const Color(0xFF7361AC) ;
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
