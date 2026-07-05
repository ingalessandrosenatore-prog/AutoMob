import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/core/widgets/buttons/am_pull_down_lg.dart';
import 'package:auto_mob_v1/core/widgets/buttons/soft_button.dart';
import 'package:auto_mob_v1/core/widgets/card/kpi_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:auto_mob_v1/core/config/performance_flags.dart';
import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_event.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/card_auto.dart';
import '../widgets/card_officina.dart';

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
    // Contenuto dell'app bar (pull-down + pill centrale + bottone +).
    // Il gruppo liquid glass lo avvolge SOLO sui top di gamma (kHeavyEffects):
    // un UNICO gruppo esterno così le forme vicine si fondono. Quando è false
    // niente gruppo => niente backdrop filter.
    final Widget appBarContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
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
                    // Sparo l'evento all'AuthBloc: la redirect del router
                    // ci riporta a /login quando lo stato diventa non
                    // autenticato. La dashboard non naviga a mano.
                    onTap: () => context.read<AuthBloc>().add(LogoutEvent()),
                    iconColor: const Color(
                      0xFF3192F3,
                    ),
                    iconSize: 22,
                    iconsWheight: FontWeight.w400,
                  ),
                  ItemMorphPopUp(
                    icon: Icons.settings_outlined,
                    text: "SETTINGS",
                    onTap: () {},
                    iconColor: const Color(
                      0xFF3192F3,
                    ),
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
                color: const Color(0xFF232326).withOpacity(0.5),
                child: const Center(
                  child: Text(
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
                   context.pushNamed('aggiungi_veicolo');
                },
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C23),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent.withOpacity(0),
        scrolledUnderElevation: 0,
        title: OCLiquidGlassGroup(
                settings: const OCLiquidGlassSettings(
                  refractStrength: -0.130,
                  blurRadiusPx: 1.0,
                  specStrength: 0,
                  specWidth: 0.0,
                  specAngle: 145,
                  blendPx: 70,
                  specPower: 10,
                ),
                child: appBarContent,
              )
           ,
      ),

      body: SmartEdge(
        blur: kHeavyEffects,
        fallbackTint:  const Color(0xFF1A1C23),
        edges: [
          EdgeBlur(
            type: EdgeType.topEdge,
            size: 160,
            tintColor: const Color(0xFF17181E),
            sigma: 10,
            controlPoints: [
              ControlPoint(position: 0.1, type: ControlPointType.visible),
              ControlPoint(position: 0.6, type: ControlPointType.visible),
              ControlPoint(position: 1.0, type: ControlPointType.transparent),
            ],
          ),
          EdgeBlur(
            type: EdgeType.bottomEdge,
            size: 135,
            tintColor:  const Color(0xFF17181E),
            sigma: 10,
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
                                          : () async {
                                              final dashboardBloc =
                                                  context.read<DashboardBloc>();
                                              final aggiornato =
                                                  await context.pushNamed(
                                                'updateKm',
                                                extra: {
                                                  'id': v.id,
                                                  'currentKm': '${v.kmCurrent}',
                                                },
                                              );
                                              // Al ritorno, se i km sono stati
                                              // aggiornati, ricarico la dashboard.
                                              if (aggiornato == true) {
                                                dashboardBloc
                                                    .add(LoadDashboardData());
                                              }
                                            },
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
                    // I KPI sono gia' pronti nello stato: il calcolo lo fa il
                    // BLoC (use case ComputeMaintenanceKpis). Qui mi limito a
                    // disegnarli, niente logica di business nella UI.
                    if (state is! DashboardLoaded || state.kpis.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final kpis = state.kpis;

                    // ListView.builder: una card per ogni KPI calcolato.
                    // shrinkWrap + NeverScrollable perche' siamo gia' dentro
                    // un SingleChildScrollView (niente scroll annidato).
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: kpis.length,
                      itemBuilder: (context, i) {
                        final kpi = kpis[i];
                        return RepaintBoundary(
                          child: AmMaintenanceKpiCard(
                            icon: kpi.type.kpiIcon,
                            color: choseColor(kpi.percentage),
                            label: kpi.type.kpiLabel,
                            remainingKm: kpi.remainingKm,
                            percentage: kpi.percentage,
                            onTap: () => _pushFunctional(context, kpi.type),
                          ),
                        );
                      },
                    );
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

  Future<void> _pushFunctional(BuildContext context, EnumPopUp type) async {
    final s = context.read<DashboardBloc>().state;
    if (s is DashboardLoaded) {
      final v = s.vehicles[s.index];
      final dashboardBloc = context.read<DashboardBloc>();
      final salvato = await context.push(
        '/addFunctional',
        extra: {'type': type, 'id': v.id, 'currentKm': v.kmCurrent},
      );
      // Al ritorno, se il lavoro e' stato salvato, ricarico la dashboard.
      if (salvato == true) {
        dashboardBloc.add(LoadDashboardData());
      }
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

/// Mapping di sola presentazione: dal tipo di manutenzione all'icona e
/// all'etichetta mostrate nella card KPI. Sta qui (UI) e non nel dominio.
extension _KpiPresentation on EnumPopUp {
  IconData get kpiIcon => switch (this) {
        EnumPopUp.aggiornaTagliando => Icons.handyman_outlined,
        EnumPopUp.aggiornaDistribuzione => Icons.settings_outlined,
        EnumPopUp.aggiornaCambioGomme => Icons.tire_repair_outlined,
        EnumPopUp.pneumaticiInversione => Icons.sync_outlined,
        EnumPopUp.revisione => Icons.verified_outlined,
        EnumPopUp.altro => Icons.build_outlined,
      };

  String get kpiLabel => switch (this) {
        EnumPopUp.aggiornaTagliando => 'tagliando',
        EnumPopUp.aggiornaDistribuzione => 'distribuzione',
        EnumPopUp.aggiornaCambioGomme => 'cambio gomme',
        EnumPopUp.pneumaticiInversione => 'inversione gomme',
        EnumPopUp.revisione => 'revisione',
        EnumPopUp.altro => 'altro',
      };
}
