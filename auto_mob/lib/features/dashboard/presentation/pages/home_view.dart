import 'dart:async';
import 'dart:io';

import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/core/widgets/buttons/am_pull_down_lg.dart';
import 'package:auto_mob_v1/core/widgets/buttons/soft_button.dart';
import 'package:auto_mob_v1/core/widgets/card/kpi_service.dart';
import 'package:auto_mob_v1/core/widgets/dialog/am_status_dialog.dart';
import 'package:auto_mob_v1/core/widgets/dialog/notification_permission_dialog.dart';
import 'package:auto_mob_v1/core/widgets/refresh/am_sliver_app_bar_delegate.dart';
import 'package:auto_mob_v1/core/widgets/refresh/am_wheel_refresh_indicator.dart';
import 'package:auto_mob_v1/core/widgets/icons/am_engine_icon.dart';
import 'package:auto_mob_v1/core/router/app_session_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:auto_mob_v1/core/config/performance_flags.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

import '../../../../core/services/haptic_service.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../bloc/notification_prompt_bloc.dart';
import '../bloc/notification_prompt_event.dart';
import '../bloc/notification_prompt_state.dart';
import '../widgets/card_auto.dart';
import '../widgets/card_officina.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key, this.initialVehicleId});

  final String? initialVehicleId;

  @override
  Widget build(BuildContext context) =>
      _HomeViewBody(initialVehicleId: initialVehicleId);
}

class _HomeViewBody extends StatefulWidget {
  const _HomeViewBody({this.initialVehicleId});

  final String? initialVehicleId;
  @override
  State<_HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<_HomeViewBody> {
  late final PageController _pageController;

  // Tiene traccia se un pop-up di stato e' attualmente aperto, per poterlo
  // chiudere prima di mostrarne un altro (evita pop-up sovrapposti).
  bool _dialogOpen = false;
  bool _initialVehicleHandled = false;

  Future<void> _openVehicleRegistration() async {
    final saved = await context.pushNamed<bool>('aggiungi_veicolo');
    if (saved == true && mounted) {
      context.read<DashboardBloc>().add(DashboardRefreshRequested());
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Carica solo se non e' gia' stato fatto: il bloc e' un singleton che
    // sopravvive ai cambi di tab, quindi rientrando in Home i dati sono
    // gia' li'. Riprova anche da DashboardError: e' l'unico modo per
    // uscire da un caricamento fallito (nessun bottone "riprova" inline).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<DashboardBloc>();
      final s = bloc.state;
      if (s is DashboardInitial || s is DashboardError) {
        bloc.add(LoadDashboardData());
        return;
      }

      // BlocListener ascolta solo i cambiamenti successivi al mount. Il bloc
      // e' un singleton e puo quindi essere gia' Loaded quando torniamo nella
      // Home: in quel caso eseguiamo qui gli effetti iniziali, compresa la
      // richiesta del permesso notifiche.
      if (s is DashboardLoaded) {
        _selectInitialVehicle(s);
        _checkNotificationPrompt(s);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _closeDialogIfOpen() {
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }
  }

  /// Effetto collaterale: in base allo stato apro/chiudo il pop-up giusto.
  /// Stesso pattern della pagina lavori: spinner durante il caricamento,
  /// warning con scorciatoia quando non ci sono ancora veicoli registrati.
  void _onStateForDialogs(BuildContext context, DashboardState s) {
    if (_dialogOpen &&
        context.read<NotificationPromptBloc>().state
            is NotificationPromptOfferRequired) {
      context.read<NotificationPromptBloc>().add(
        const NotificationPromptOfferInterrupted(),
      );
    }
    _closeDialogIfOpen();

    // Errore one-shot dell'aggiornamento foto: lo mostro senza toccare i dati.
    if (s is DashboardLoaded && s.photoUpdateError != null) {
      _dialogOpen = true;
      showAmStatusDialog(
        context,
        icon: HugeIcons.strokeRoundedAlert01,
        iconColor: const Color(0xFFFF453A),
        title: 'Foto non aggiornata',
        message: s.photoUpdateError,
        actions: [
          AmDialogAction(
            label: 'Chiudi',
            color: const Color(0xFF8E8E93),
            onPressed: _closeDialogIfOpen,
          ),
        ],
      );
      return;
    }

    if (s is DashboardLoading || s is DashboardInitial) {
      _dialogOpen = true;
      showAmStatusDialog(
        context,
        showSpinner: true,
        iconColor: const Color(0xFFFF6B00),
        title: 'Caricamento',
        message: 'Sto recuperando i tuoi veicoli…',
      );
      return;
    }

    if (s is DashboardLoaded &&
        s.vehicles.length == 1 &&
        s.vehicles.first.isPlaceholder) {
      _dialogOpen = true;
      showAmStatusDialog(
        context,
        icon: HugeIcons.strokeRoundedGarage,
        iconColor: const Color(0xFFFFB4AB),
        title: 'Registra il tuo primo veicolo',
        message:
            'Non hai ancora nessun veicolo. Aggiungine uno per '
            'iniziare a usare AutoMob.',
        actions: [
          AmDialogAction(
            label: 'Annulla',
            color: const Color(0xFF8E8E93),
            onPressed: _closeDialogIfOpen,
          ),
          AmDialogAction(
            label: 'Registra',
            color: const Color(0xFFFF6B00),
            filled: true,
            onPressed: () {
              _closeDialogIfOpen();
              _openVehicleRegistration();
            },
          ),
        ],
      );
      return;
    }

    if (s is DashboardLoaded) {
      _selectInitialVehicle(s);
      _checkNotificationPrompt(s);
    }
  }

  void _selectInitialVehicle(DashboardLoaded state) {
    final vehicleId = widget.initialVehicleId;
    if (_initialVehicleHandled || vehicleId == null) return;
    _initialVehicleHandled = true;

    final index = state.vehicles.indexWhere(
      (vehicle) => vehicle.id == vehicleId,
    );
    if (index < 0) return;
    context.read<DashboardBloc>().add(DashboardPageChanged(index));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(index);
      }
    });
  }

  void _checkNotificationPrompt(DashboardLoaded state) {
    context.read<NotificationPromptBloc>().add(
      NotificationPromptCheckRequested(
        hasRealVehicles:
            state.vehicles.isNotEmpty &&
            state.vehicles.any((vehicle) => !vehicle.isPlaceholder),
      ),
    );
  }

  void _onNotificationPromptState(
    BuildContext context,
    NotificationPromptState state,
  ) {
    switch (state) {
      case NotificationPromptOfferRequired():
        if (_dialogOpen) return;
        _dialogOpen = true;
        unawaited(
          showNotificationPermissionDialog(
            context,
            onPostpone: () {
              _closeDialogIfOpen();
              context.read<NotificationPromptBloc>().add(
                const NotificationPromptPostponeRequested(),
              );
            },
            onEnable: () {
              _closeDialogIfOpen();
              context.read<NotificationPromptBloc>().add(
                const NotificationPromptEnableRequested(),
              );
            },
          ).whenComplete(() => _dialogOpen = false),
        );
      case NotificationPromptFailure(:final message):
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(message)));
      case NotificationPromptInitial():
      case NotificationPromptChecking():
      case NotificationPromptNotRequired():
      case NotificationPromptPostponing():
      case NotificationPromptRequesting():
      case NotificationPromptEnabled():
      case NotificationPromptDenied():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
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
                backgroundColor: kHeavyEffects
                    ? colors.surfaceRaised.withValues(alpha: 0.2)
                    : colors.surfaceRaised,
                popupBackgroundColor: kHeavyEffects
                    ? colors.surfaceRaised.withValues(alpha: 0.5)
                    : colors.surfaceRaised,
                buttonIcons: HugeIcons.strokeRoundedMoreHorizontalCircle02,
                buttonIconsSize: 26,
                iconColor: colors.textPrimary,
                textColor: colors.textPrimary,
                buttonLableStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
                arrow: false,
                children: [
                  ItemMorphPopUp(
                    icon: HugeIcons.strokeRoundedLogout01,
                    text: "LOGOUT",
                    onTap: AppSessionActions.logout,
                    iconColor: colors.info,
                    textColor: colors.textPrimary,
                    iconSize: 22,
                    iconsWheight: FontWeight.w400,
                  ),
                  ItemMorphPopUp(
                    icon: HugeIcons.strokeRoundedSettings01,
                    text: "SETTINGS",
                    onTap: () => context.push('/settings'),
                    iconColor: colors.info,
                    textColor: colors.textPrimary,
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
              child: Center(
                child: Text(
                  "VEICOLI",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colors.textPrimary,
                    shadows: [
                      Shadow(
                        color: colors.shadow,
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
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
                color: colors.accent,
                icon: HugeIcons.strokeRoundedAdd01,
                onPressed: _openVehicleRegistration,
              ),
            ),
          ),
        ],
      ),
    );

    // Altezza reale del contenuto della Row dell'app bar: Padding(v:12)*2 +
    // 45 (altezza di pillola/bottoni). Serve per dimensionare lo sliver.
    const appBarContentHeight = 69.0;
    final topSafeArea = MediaQuery.paddingOf(context).top;

    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (previous, current) {
            if (previous.runtimeType != current.runtimeType) return true;
            if (previous is DashboardLoaded && current is DashboardLoaded) {
              return previous.vehicles != current.vehicles ||
                  previous.photoUpdateError != current.photoUpdateError;
            }
            return false;
          },
          listener: _onStateForDialogs,
        ),
        BlocListener<NotificationPromptBloc, NotificationPromptState>(
          listener: _onNotificationPromptState,
        ),
      ],
      child: Scaffold(
        backgroundColor: colors.background,
        body: SmartEdge(
          blur: kHeavyEffects,
          opacity: 0.96,
          fallbackTint: colors.background,
          edges: [
            EdgeBlur(
              type: EdgeType.topEdge,
              size: 72,
              tintColor: colors.background,
              sigma: 10,
              controlPoints: [
                ControlPoint(position: 0.5, type: ControlPointType.visible),
                ControlPoint(position: 1.0, type: ControlPointType.transparent),
              ],
            ),
            EdgeBlur(
              type: EdgeType.bottomEdge,
              size: 92,
              tintColor: colors.background,
              sigma: 10,
              controlPoints: [
                ControlPoint(position: 0.5, type: ControlPointType.visible),
                ControlPoint(position: 1.0, type: ControlPointType.transparent),
              ],
            ),
          ],
          // CustomScrollView + sliver refresh control: a differenza di un
          // overlay, questo spinge fisicamente giu' l'header (sliver dopo di
          // lui) durante il pull e lo tiene giu' finche' il refresh non finisce.
          child: CustomScrollView(
            // AlwaysScrollable+Bouncing: CupertinoSliverRefreshControl richiede
            // overscroll per attivarsi, non disponibile con Clamping (default Android).
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              AmRefreshControlSliver(onRefresh: () => _handleRefresh(context)),
              SliverPersistentHeader(
                pinned: true,
                delegate: AmSliverAppBarDelegate(
                  height: topSafeArea + appBarContentHeight,
                  child: Padding(
                    padding: EdgeInsets.only(top: topSafeArea),
                    // Gruppo glass solo sui top di gamma (come da commento
                    // sopra): con flag off niente backdrop shader da
                    // ricompilare/ridisegnare ad ogni frame.
                    child: OCLiquidGlassGroup(
                      settings: const OCLiquidGlassSettings(
                        refractStrength: -0.13,
                        blurRadiusPx: 1.0,
                        specStrength: 0,
                        specWidth: 0.0,
                        specAngle: 145,
                        blendPx: 20,
                        specPower: 10,
                      ),
                      child: appBarContent,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // lista auto
                    BlocBuilder<DashboardBloc, DashboardState>(
                      builder: (context, state) {
                        if (state is DashboardLoading ||
                            state is DashboardInitial) {
                          // Il caricamento e' comunicato dal pop-up di stato
                          // (BlocListener sopra): il body resta vuoto dietro di esso.
                          return const SizedBox.shrink();
                        }
                        if (state is DashboardError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFF453A),
                                ),
                              ),
                            ),
                          );
                        }
                        if (state is DashboardLoaded) {
                          final vehicles = state.vehicles;
                          // Prima: SizedBox(height: 420) fisso -> il PageView stirava
                          // la card fino a 420px lasciando una banda vuota sotto
                          // (visibile su device reale). Ora l'altezza la detta il
                          // CONTENUTO: una CardAuto invisibile (Opacity 0, nessun
                          // decode immagine, nessuna interazione) fa da "righello" e
                          // il PageView la riempie con Positioned.fill. Si adatta da
                          // solo a textScale/dimensioni schermo, senza numeri magici.
                          final measure = vehicles.first;
                          return Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    IgnorePointer(
                                      child: ExcludeSemantics(
                                        child: Opacity(
                                          opacity: 0,
                                          child: CardAuto(
                                            marca: measure.brand,
                                            modello: measure.model,
                                            kmTotali: '0 km',
                                            targa: measure.plate,
                                            anno: measure.year,
                                            nextRevisionDate:
                                                measure.nextRevisionDate,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: SmartEdge(
                                        blur: kHeavyEffects,
                                        fallbackTint: colors.background,
                                        edges: [
                                          EdgeBlur(
                                            type: EdgeType.leftEdge,
                                            size: 10,
                                            tintColor: colors.background,
                                            sigma: 10,
                                            controlPoints: [
                                              ControlPoint(
                                                position: 0.5,
                                                type: ControlPointType.visible,
                                              ),
                                              ControlPoint(
                                                position: 1.0,
                                                type: ControlPointType
                                                    .transparent,
                                              ),
                                            ],
                                          ),
                                          EdgeBlur(
                                            type: EdgeType.rightEdge,
                                            size: 10,
                                            tintColor: colors.background,
                                            sigma: 10,
                                            controlPoints: [
                                              ControlPoint(
                                                position: 0.5,
                                                type: ControlPointType.visible,
                                              ),
                                              ControlPoint(
                                                position: 1.0,
                                                type: ControlPointType
                                                    .transparent,
                                              ),
                                            ],
                                          ),
                                        ],
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
                                            final mileageEstimate = v
                                                .mileageEstimateAt(
                                                  DateTime.now(),
                                                );
                                            // TODO: spostare logica nella UI, spostare in bloc in. futuro
                                            return RepaintBoundary(
                                              child: CardAuto(
                                                marca: v.brand,
                                                modello: v.model,
                                                kmTotali: v.isPlaceholder
                                                    ? '—'
                                                    : '${v.kmCurrent} km',
                                                targa: v.plate,
                                                immaginePath: v.fotoPath,
                                                anno: v.year,
                                                kmUpdatedAt: v.kmUpdatedAt,
                                                estimatedAdditionalKm:
                                                    mileageEstimate
                                                        .additionalKm,
                                                daysSinceKmUpdate:
                                                    mileageEstimate
                                                        .daysSinceUpdate,
                                                nextRevisionDate:
                                                    v.nextRevisionDate,
                                                onRevisionTap: v.isPlaceholder
                                                    ? null
                                                    : () async {
                                                        final dashboardBloc =
                                                            context
                                                                .read<
                                                                  DashboardBloc
                                                                >();
                                                        final aggiornato =
                                                            await context.pushNamed(
                                                              'updateRevision',
                                                              extra: {
                                                                'id': v.id,
                                                                'currentRevisionDate':
                                                                    v.nextRevisionDate,
                                                              },
                                                            );
                                                        if (aggiornato ==
                                                            true) {
                                                          dashboardBloc.add(
                                                            LoadDashboardData(),
                                                          );
                                                        }
                                                      },
                                                onKmTap: v.isPlaceholder
                                                    ? null
                                                    : () async {
                                                        final dashboardBloc =
                                                            context
                                                                .read<
                                                                  DashboardBloc
                                                                >();
                                                        final aggiornato =
                                                            await context.pushNamed(
                                                              'updateKm',
                                                              extra: {
                                                                'id': v.id,
                                                                'currentKm':
                                                                    '${v.kmCurrent}',
                                                                'estimatedKm':
                                                                    mileageEstimate
                                                                        .estimatedKm,
                                                              },
                                                            );
                                                        // Al ritorno, se i km sono stati
                                                        // aggiornati, ricarico la dashboard.
                                                        if (aggiornato ==
                                                            true) {
                                                          dashboardBloc.add(
                                                            LoadDashboardData(),
                                                          );
                                                        }
                                                      },
                                                onEditPhotoTap: v.isPlaceholder
                                                    ? null
                                                    : () async {
                                                        final dashboardBloc =
                                                            context
                                                                .read<
                                                                  DashboardBloc
                                                                >();
                                                        final picker =
                                                            ImagePicker();
                                                        final picked = await picker.pickImage(
                                                          source: ImageSource
                                                              .gallery,
                                                          // Ridimensiona/ricomprime a
                                                          // monte (nativo): una foto card
                                                          // 2:1 non ha bisogno di 12MP,
                                                          // ed evita decode enormi sul
                                                          // main isolate.
                                                          maxWidth: 1280,
                                                          maxHeight: 1280,
                                                          imageQuality: 80,
                                                        );
                                                        if (picked == null) {
                                                          return;
                                                        }
                                                        dashboardBloc.add(
                                                          VehiclePhotoUpdateRequested(
                                                            targa: v.plate,
                                                            foto: File(
                                                              picked.path,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                              ),
                                            );
                                            //fine TODO: spostare logica nella UI, spostare in bloc in. futuro
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AnimatedSmoothIndicator(
                                  activeIndex: state.index,
                                  count: vehicles.length,
                                  effect: ExpandingDotsEffect(
                                    dotHeight: 8,
                                    dotWidth: 8,
                                    expansionFactor: 2,
                                    activeDotColor: colors.accent,
                                    dotColor: colors.textSecondary.withValues(
                                      alpha: 0.55,
                                    ),
                                    radius: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    /* // --- BANNERS ---
                    AmBannerBig(
                      title: 'Risparmia 215€/anno',
                      subtitle: 'Assicura Facile',
                      buttonLabel: 'Calcola preventivo',
                      // imagePath: 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?q=80&w=2073&auto=format&fit=crop',
                      //  logoPath: 'https://images.unsplash.com/photo-1599305090748-36655bc6f571?q=80&w=2070&auto=format&fit=crop', // Placeholder logo
                      onTap: () {},
                    ),*/

                    // lista kpi per il veicolo corrente
                    BlocBuilder<DashboardBloc, DashboardState>(
                      buildWhen: (previous, current) =>
                          previous is! DashboardLoaded ||
                          current is! DashboardLoaded ||
                          previous.index != current.index ||
                          previous.vehicles != current.vehicles,
                      builder: (context, state) {
                        final vehicle = state is DashboardLoaded
                            ? state.vehicles[state.index]
                            : null;
                        final mechanic = vehicle?.mechanic;
                        return Padding(
                          padding: const EdgeInsets.all(9),
                          child: RepaintBoundary(
                            child: AmWorkshopCard(
                              mechanic: mechanic,
                              onTap: vehicle == null || vehicle.isPlaceholder
                                  ? null
                                  : () async {
                                      AmHaptics.tap();
                                      final dashboardBloc = context
                                          .read<DashboardBloc>();
                                      final connected = await context.pushNamed(
                                        'mechanicDetails',
                                        extra: <String, dynamic>{
                                          'vehicleId': vehicle.id,
                                          'mechanic': mechanic,
                                        },
                                      );
                                      if (connected == true) {
                                        AmHaptics.tap();
                                        dashboardBloc.add(
                                          DashboardRefreshRequested(),
                                        );
                                      }
                                    },
                            ),
                          ),
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.all(9.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "STATO VEICOLO",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: colors.textPrimary,
                              shadows: [
                                Shadow(
                                  color: colors.shadow,
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCarAlert,
                            color: colors.accent,
                            size: 24,
                            strokeWidth: 2.2,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9.0),
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
                                  iconBuilder: kpi.type.kpiIconBuilder,
                                  color: choseColor(kpi.percentage),
                                  label: kpi.type.kpiLabel,
                                  remainingKm: kpi.remainingKm,
                                  percentage: kpi.percentage,
                                  onTap: () =>
                                      _pushFunctional(context, kpi.type),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    /* Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9.0,
                        vertical: 9.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "IN OFFERTA PER TE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "Vedi tutti >",
                              style: TextStyle(
                                color: colors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 9.0),
                      child: Row(
                        spacing: 8,
                        children: [
                          AmBannerSmall(
                            discount: '-30%',
                            brandName: 'otoTOP',
                            productName: 'Olio motore 10W/40 1L',
                            price: '34,90€',
                            oldPrice: '49,90€',
                            //  imagePath: 'https://images.unsplash.com/photo-1621252179027-94459d278660?q=80&w=1000&auto=format&fit=crop',
                            brandLogo: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'o',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {},
                          ),

                          AmBannerSmall(
                            discount: '-40%',
                            brandName: 'LumaCar',
                            productName: 'Kit LED interni touch',
                            price: '23,90€',
                            oldPrice: '39,90€',
                            //  imagePath: 'https://images.unsplash.com/photo-1542362567-b05503f35259?q=80&w=1000&auto=format&fit=crop',
                            brandLogo: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {},
                          ),
                          AmBannerSmall(
                            discount: '-40%',
                            brandName: 'LumaCar',
                            productName: 'Kit LED interni touch',
                            price: '23,90€',
                            oldPrice: '39,90€',
                            //  imagePath: 'https://images.unsplash.com/photo-1542362567-b05503f35259?q=80&w=1000&auto=format&fit=crop',
                            brandLogo: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {},
                          ),
                          AmBannerSmall(
                            discount: '-40%',
                            brandName: 'LumaCar',
                            productName: 'Kit LED interni touch',
                            price: '23,90€',
                            oldPrice: '39,90€',
                            //  imagePath: 'https://images.unsplash.com/photo-1542362567-b05503f35259?q=80&w=1000&auto=format&fit=crop',
                            brandLogo: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'L',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- END BANNERS --- */
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dispaccia il pull-to-refresh e attende il completamento (isRefreshing
  /// torna false), sia in caso di successo che di errore.
  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<DashboardBloc>();
    bloc.add(DashboardRefreshRequested());
    await bloc.stream.firstWhere(
      (s) => s is! DashboardLoaded || !s.isRefreshing,
    );
  }

  Future<void> _pushFunctional(BuildContext context, EnumPopUp type) async {
    final s = context.read<DashboardBloc>().state;
    AmHaptics.tap();
    if (s is DashboardLoaded) {
      final v = s.vehicles[s.index];
      final dashboardBloc = context.read<DashboardBloc>();
      final salvato = await context.pushNamed(
        'aggiungi_lavoro',
        extra: {
          'vehicleId': v.id,
          'currentKm': v.kmCurrent,
          'initialWorkType': type,
        },
      );
      // Al ritorno, se il lavoro e' stato salvato, ricarico la dashboard.
      if (salvato == true) {
        dashboardBloc.add(LoadDashboardData());
      }
    }
  }

  Color choseColor(double perc) {
    if (perc <= 0) {
      return const Color(0xFFFF453A);
    }
    if (perc >= 50) {
      return const Color(0xFF3192F3);
    }
    return const Color(0xFFFF6B00);
  }
}

/// Mapping di sola presentazione: dal tipo di manutenzione all'icona e
/// all'etichetta mostrate nella card KPI. Sta qui (UI) e non nel dominio.
extension _KpiPresentation on EnumPopUp {
  Widget Function(double size, Color color) get kpiIconBuilder =>
      switch (this) {
        EnumPopUp.aggiornaTagliando => (s, c) => HugeIcon(
          icon: HugeIcons.strokeRoundedTools,
          size: s,
          color: c,
          strokeWidth: 2.2,
        ),
        EnumPopUp.aggiornaDistribuzione => (s, c) => AmEngineIcon(
          size: s,
          color: c,
        ),
        EnumPopUp.aggiornaCambioGomme => (s, c) => HugeIcon(
          icon: HugeIcons.strokeRoundedTire,
          size: s,
          color: c,
          strokeWidth: 2.2,
        ),
        EnumPopUp.pneumaticiInversione => (s, c) => HugeIcon(
          icon: HugeIcons.strokeRoundedRefresh,
          size: s,
          color: c,
          strokeWidth: 2.2,
        ),
        EnumPopUp.revisione => (s, c) => HugeIcon(
          icon: HugeIcons.strokeRoundedValidation,
          size: s,
          color: c,
          strokeWidth: 2.2,
        ),
        EnumPopUp.altro => (s, c) => HugeIcon(
          icon: HugeIcons.strokeRoundedTools,
          size: s,
          color: c,
          strokeWidth: 2.2,
        ),
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
