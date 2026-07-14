import 'package:auto_mob_v1/core/widgets/dialog/am_status_dialog.dart';
import 'package:auto_mob_v1/core/widgets/refresh/am_sliver_app_bar_delegate.dart';
import 'package:auto_mob_v1/core/widgets/refresh/am_wheel_refresh_indicator.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/work_log_add_button.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/work_log_item_card.dart';
import 'package:auto_mob_v1/core/widgets/buttons/am_pull_down_lg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:auto_mob_v1/core/config/performance_flags.dart';
import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import '../../domain/entities/vehicle_option.dart';
import '../../domain/entities/work_log_row.dart';
import '../bloc/work_log_history_bloc.dart';
import '../bloc/work_log_history_event.dart';
import '../bloc/work_log_history_state.dart';

const Color _orange = Color(0xFFFF6B00);

/// Pagina dello storico lavori (WorkLog).
/// Veicoli selezionabili dal dropdown + cronologia interventi paginata.
class WorkLogHistoryPage extends StatelessWidget {
  const WorkLogHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // .value: il bloc e' un lazySingleton che sopravvive ai cambi di tab.
    // Con `create:` flutter_bloc lo chiuderebbe ogni volta che si esce da
    // questa pagina, e al rientro GetIt restituirebbe la stessa istanza
    // ormai chiusa -> crash al primo evento.
    return BlocProvider<WorkLogHistoryBloc>.value(
      value: GetIt.I<WorkLogHistoryBloc>(),
      child: const _WorkLogHistoryBody(),
    );
  }
}

class _WorkLogHistoryBody extends StatefulWidget {
  const _WorkLogHistoryBody();

  @override
  State<_WorkLogHistoryBody> createState() => _WorkLogHistoryBodyState();
}

class _WorkLogHistoryBodyState extends State<_WorkLogHistoryBody> {
  final ScrollController _scroll = ScrollController();

  // Tiene traccia se un pop-up di stato e' attualmente aperto, per poterlo
  // chiudere prima di mostrarne un altro (evita pop-up sovrapposti).
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Lancio il caricamento dopo il primo frame, cosi' il BlocListener e' gia'
    // in ascolto e cattura la transizione verso "loading" (pop-up spinner).
    // Solo pero' se non e' gia' stato fatto: il bloc e' un singleton che
    // sopravvive ai cambi di tab, quindi rientrando qui i dati sono gia'
    // li'. Riprova anche da HistoryStatus.error (stesso effetto di "Riprova").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<WorkLogHistoryBloc>();
      final status = bloc.state.status;
      if (status == HistoryStatus.initial || status == HistoryStatus.error) {
        bloc.add(const LoadInitial());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Quando manco 300px alla fine, chiedo la fetta successiva. Le 3 guardie
  /// (sto caricando / ho finito / droppable) stanno nel bloc.
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<WorkLogHistoryBloc>().add(const LoadMore());
    }
  }

  void _closeDialogIfOpen() {
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }
  }

  /// Effetto collaterale: in base allo stato apro/chiudo il pop-up giusto.
  /// "Nessun lavoro" NON e' qui: e' uno stato vuoto inline nel body.
  void _onStateForDialogs(BuildContext context, WorkLogHistoryState s) {
    _closeDialogIfOpen();

    switch (s.status) {
      case HistoryStatus.loading:
        _dialogOpen = true;
        showAmStatusDialog(
          context,
          showSpinner: true,
          iconColor: _orange,
          title: 'Caricamento',
          message: 'Sto recuperando lo storico…',
        );
        break;

      case HistoryStatus.error:
        _dialogOpen = true;
        showAmStatusDialog(
          context,
          icon: HugeIcons.strokeRoundedAlert01,
          iconColor: const Color(0xFFFF453A),
          title: 'Qualcosa è andato storto',
          message: s.errorMessage ?? 'Riprova tra qualche istante.',
          actions: [
            AmDialogAction(
              label: 'Chiudi',
              color: const Color(0xFF8E8E93),
              onPressed: () {
                _closeDialogIfOpen();
                context.go('/home');
              },
            ),
            AmDialogAction(
              label: 'Riprova',
              color: _orange,
              filled: true,
              onPressed: () {
                _closeDialogIfOpen();
                context.read<WorkLogHistoryBloc>().add(const Retry());
              },
            ),
          ],
        );
        break;

      case HistoryStatus.loaded:
        // Pronto ma senza veicoli: warning con scorciatoia all'aggiunta.
        if (s.vehicles.isEmpty) {
          _dialogOpen = true;
          showAmStatusDialog(
            context,
            icon: HugeIcons.strokeRoundedGarage,
            iconColor: const Color(0xFFFFB4AB),
            title: 'Nessun veicolo trovato',
            message: 'Aggiungi un veicolo per iniziare a registrare i lavori.',
            actions: [
              AmDialogAction(
                label: 'Chiudi',
                color: const Color(0xFF8E8E93),
                onPressed: () {
                  _closeDialogIfOpen();
                  context.go('/home');
                },
              ),
              AmDialogAction(
                label: 'Aggiungi',
                color: _orange,
                filled: true,
                onPressed: () {
                  _closeDialogIfOpen();
                  context.pushNamed('aggiungi_veicolo');
                },
              ),
            ],
          );
        }
        break;

      case HistoryStatus.initial:
        break;
    }
  }

  /// Dispaccia il pull-to-refresh e attende il completamento (isRefreshing
  /// torna false), sia in caso di successo che di errore. Un solo punto
  /// condiviso: il refresh control ora vive una volta sola nel body, non
  /// piu' duplicato per ogni branch di _WorkListView.
  Future<void> _handleRefresh(BuildContext context) async {
    final bloc = context.read<WorkLogHistoryBloc>();
    bloc.add(const RefreshRequested());
    await bloc.stream.firstWhere((s) => !s.isRefreshing);
  }

  @override
  Widget build(BuildContext context) {
    // Altezza reale del contenuto della Row dell'app bar: Padding(v:12)*2 +
    // 45 (altezza di pillola/bottoni). Serve per dimensionare lo sliver.
    const appBarContentHeight = 69.0;
    final topSafeArea = MediaQuery.paddingOf(context).top;
    final colors = AmThemeColors.of(context);

    return BlocListener<WorkLogHistoryBloc, WorkLogHistoryState>(
      listenWhen: (p, c) => p.status != c.status || p.vehicles != c.vehicles,
      listener: _onStateForDialogs,
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            SmartEdge(
              blur: kHeavyEffects,
              fallbackTint: colors.background,
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
                  tintColor: colors.background,
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
              // CustomScrollView + sliver refresh control: a differenza di un
              // overlay, questo spinge fisicamente giu' l'header (sliver dopo
              // di lui) durante il pull e lo tiene giu' finche' il refresh
              // non finisce.
              child: CustomScrollView(
                controller: _scroll,
                // AlwaysScrollable+Bouncing: CupertinoSliverRefreshControl
                // richiede overscroll per attivarsi, non disponibile con
                // Clamping (default Android).
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  AmRefreshControlSliver(
                    onRefresh: () => _handleRefresh(context),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: AmSliverAppBarDelegate(
                      height: topSafeArea + appBarContentHeight,
                      child: Padding(
                        padding: EdgeInsets.only(top: topSafeArea),
                        // Header glass solo sui top di gamma: era una causa
                        // dello scatto entrando nel tab (ricompilazione shader
                        // al primo disegno). Con flag off resta l'header piatto.
                        child: kHeavyEffects
                            ? const OCLiquidGlassGroup(
                                settings: OCLiquidGlassSettings(
                                  refractStrength: -0.130,
                                  blurRadiusPx: 1.0,
                                  specStrength: 0,
                                  specWidth: 0.0,
                                  specAngle: 145,
                                  blendPx: 20,
                                  specPower: 10,
                                ),
                                child: _AppBarContent(),
                              )
                            : const _AppBarContent(),
                      ),
                    ),
                  ),
                  BlocBuilder<WorkLogHistoryBloc, WorkLogHistoryState>(
                    builder: (context, state) => _WorkListView(state: state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra superiore: dropdown veicoli (dinamico) + pill "LAVORI" + bottone +.
class _AppBarContent extends StatelessWidget {
  const _AppBarContent();

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: BlocBuilder<WorkLogHistoryBloc, WorkLogHistoryState>(
                buildWhen: (p, c) =>
                    p.vehicles != c.vehicles ||
                    p.selectedVehicleId != c.selectedVehicleId,
                builder: (context, state) => _VehicleDropdown(state: state),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  "LAVORI",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colors.textPrimary,
                    shadows: const [
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

          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: BlocBuilder<WorkLogHistoryBloc, WorkLogHistoryState>(
                buildWhen: (previous, current) =>
                    previous.vehicles != current.vehicles ||
                    previous.selectedVehicleId != current.selectedVehicleId,
                builder: (context, state) {
                  VehicleOption? selected;
                  for (final vehicle in state.vehicles) {
                    if (vehicle.id == state.selectedVehicleId) {
                      selected = vehicle;
                      break;
                    }
                  }
                  return WorkLogAddButton(
                    vehicle: selected,
                    onMissingVehicle: () =>
                        context.pushNamed('aggiungi_veicolo'),
                    onSaved: () => context.read<WorkLogHistoryBloc>().add(
                      const ReloadCurrent(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown veicoli alimentato dallo stato. Al tap su una voce dispatcho
/// VehicleChanged e chiudo il pop-up.
class _VehicleDropdown extends StatelessWidget {
  final WorkLogHistoryState state;
  const _VehicleDropdown({required this.state});

  @override
  Widget build(BuildContext context) {
    VehicleOption? selected;
    for (final v in state.vehicles) {
      if (v.id == state.selectedVehicleId) {
        selected = v;
        break;
      }
    }

    final children = state.vehicles
        .map(
          (v) => ItemMorphPopUp(
            icon: HugeIcons.strokeRoundedCar05,
            text: v.nome.isEmpty ? v.targa : v.nome,
            iconSize: 22,
            iconColor: _orange,
            iconsWheight: FontWeight.w100,
            onTap: () {
              context.read<WorkLogHistoryBloc>().add(VehicleChanged(v.id));
              Navigator.of(context).maybePop();
            },
          ),
        )
        .toList();

    return AmPullDownLG(
      brand: selected?.brand ?? '',
      onTap: () {},
      lable: selected?.nome ?? 'VEICOLO',
      larghezza: 200,
      buttonIcons: HugeIcons.strokeRoundedCar05,
      buttonIconsSize: 20,
      buttonIconColor: Colors.white,
      buttonLableStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
      arrow: true,
      children: children,
    );
  }
}

/// La lista vera: gestisce i 3 casi (spinner inline, vuoto, lista paginata).
/// Ritorna sempre UNO sliver, per stare dentro la CustomScrollView condivisa
/// del body insieme al refresh control e all'app bar sliver (niente
/// ListView/ListView.builder qui: creerebbero uno scroll annidato
/// indipendente e romperebbero il pull-to-refresh condiviso).
class _WorkListView extends StatelessWidget {
  final WorkLogHistoryState state;
  const _WorkListView({required this.state});

  @override
  Widget build(BuildContext context) {
    final works = state.works;

    if (works.isEmpty) {
      // Cambio veicolo / refresh in corso: spinner centrale.
      if (state.isLoadingMore) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: 140),
              child: CircularProgressIndicator(color: _orange),
            ),
          ),
        );
      }
      // Pronto ma il veicolo non ha lavori: messaggio inline (niente pop-up).
      if (state.status == HistoryStatus.loaded &&
          state.selectedVehicleId != null) {
        return const SliverToBoxAdapter(child: _EmptyWorks());
      }
      // Primo caricamento: il body resta vuoto dietro al pop-up spinner.
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == works.length) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: _orange),
                  ),
                );
              }
              return const SizedBox(
                height: 120,
              ); // spazio finale sotto la lista
            }

            final w = works[i];
            return WorkLogItemCard(
              title: _workTitle(w),
              date: _formatDate(w.serviceDate),
              km: _formatKm(w.serviceKm),
              description: (w.notes != null && w.notes!.trim().isNotEmpty)
                  ? w.notes!.trim()
                  : '—',
              hasWorkshop: w.hasWorkshop,
            );
          },
          childCount: works.length + 1, // +1 = footer (spinner o spazio finale)
        ),
      ),
    );
  }
}

/// Stato vuoto inline mostrato quando il veicolo non ha ancora lavori.
class _EmptyWorks extends StatelessWidget {
  const _EmptyWorks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 140, left: 32, right: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTransactionHistory,
              size: 64,
              color: Colors.white.withValues(alpha: 0.25),
              strokeWidth: 2.2,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessun lavoro ancora inserito',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi un intervento con il tasto + in alto.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Mapping di sola presentazione (String, non Widget) --------------------

/// Etichetta mostrata in card: tipo manutenzione o nome libero per "altro".
String _workTitle(WorkLogRow w) {
  switch (w.type) {
    case 'tagliando':
      return 'Tagliando';
    case 'distribuzione':
      return 'Distribuzione';
    case 'revisione':
      return 'Revisione';
    case 'pneumatici_cambio':
      return 'Cambio gomme';
    case 'pneumatici_inversione':
      return 'Inversione gomme';
    case 'altro':
      final name = w.customName?.trim() ?? '';
      return name.isNotEmpty ? name : 'Altro';
    default:
      return w.type;
  }
}

/// Data in formato italiano breve: "16 Giu 2026".
String _formatDate(DateTime d) {
  const mesi = [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ];
  final giorno = d.day.toString().padLeft(2, '0');
  return '$giorno ${mesi[d.month - 1]} ${d.year}';
}

/// Km con separatore migliaia: "42.000 km".
String _formatKm(int km) {
  final s = km.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '$buf km';
}
