import 'dart:async';

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_feature_contract.dart';
import '../domain/work_log_launch_context.dart';
import '../domain/work_log_use_cases.dart';
import '../domain/work_log_vehicle.dart';
import '../domain/work_log_type.dart';
import 'work_log_bloc.dart';
import 'work_log_detail_page.dart';
import 'work_log_editor_cubit.dart';
import 'work_log_history_edge.dart';
import 'work_log_history_filter.dart';
import 'work_log_item_card.dart';
import 'work_log_route_transition.dart';
import 'work_log_top_app_bar.dart';
import 'work_log_vehicles_cubit.dart';
import 'work_log_wizard_body.dart';

/// Entrypoint verticale condiviso da AutoMob e dal backoffice meccanico.
/// Le app iniettano solo repository, modalità iniziale e callback esterni.
class WorkLogFeature extends StatelessWidget {
  const WorkLogFeature({
    required this.launch,
    required this.dependencies,
    super.key,
    this.onNotificationsPressed,
    this.onCloseRequested,
    this.routeAnimation,
  });

  final WorkLogLaunch launch;
  final WorkLogDependencies dependencies;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCloseRequested;
  // L'app owner passa l'animazione della shell per sincronizzare soltanto il
  // repaint del glass durante lo slide; le route interne restano indipendenti.
  final Listenable? routeAnimation;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => WorkLogVehiclesCubit(
          getWorkLogVehicles: GetWorkLogVehicles(dependencies.repository),
        ),
      ),
      BlocProvider(
        create: (_) => WorkLogHistoryBloc(
          getVehicleWorkHistory: GetVehicleWorkHistory(dependencies.repository),
        ),
      ),
      BlocProvider(create: (_) => _WorkLogRouteTransitionCubit()),
    ],
    child: _WorkLogFeatureView(
      key: ValueKey(switch (launch) {
        OwnerWorkLogLaunch() => 'owner',
        MechanicWorkLogLaunch(:final vehicle) => 'mechanic-${vehicle.id}',
      }),
      launch: launch,
      dependencies: dependencies,
      onNotificationsPressed: onNotificationsPressed,
      onCloseRequested: onCloseRequested,
      routeAnimation: routeAnimation,
    ),
  );
}

class _WorkLogFeatureView extends StatefulWidget {
  const _WorkLogFeatureView({
    required this.launch,
    required this.dependencies,
    super.key,
    this.onNotificationsPressed,
    this.onCloseRequested,
    this.routeAnimation,
  });

  final WorkLogLaunch launch;
  final WorkLogDependencies dependencies;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCloseRequested;
  final Listenable? routeAnimation;

  @override
  State<_WorkLogFeatureView> createState() => _WorkLogFeatureViewState();
}

class _WorkLogFeatureViewState extends State<_WorkLogFeatureView> {
  ModalRoute<dynamic>? _boundRoute;
  Timer? _routeTransitionTimer;
  final _routeTransitions = WorkLogRouteTransitionCoordinator();

  @override
  void initState() {
    super.initState();
    final vehicles = context.read<WorkLogVehiclesCubit>();
    switch (widget.launch) {
      case OwnerWorkLogLaunch(:final initialVehicleId):
        vehicles.load(initialVehicleId: initialVehicleId);
      case MechanicWorkLogLaunch(:final vehicle):
        vehicles.seed(vehicle);
        context.read<WorkLogHistoryBloc>().add(
          WorkLogHistoryOpened(vehicle.id),
        );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bindRouteTransition();
      });
      return;
    }
    _bindRouteTransition(route);
  }

  void _bindRouteTransition([ModalRoute<dynamic>? modalRoute]) {
    final route = modalRoute ?? ModalRoute.of(context);
    if (route == null || identical(route, _boundRoute)) return;
    _boundRoute = route;
    _routeTransitionTimer?.cancel();

    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final duration = route.transitionDuration;
    if (route.isFirst || animationsDisabled || duration == Duration.zero) {
      context.read<_WorkLogRouteTransitionCubit>().markSettled();
      return;
    }
    _routeTransitionTimer = Timer(duration, () {
      if (mounted) {
        context.read<_WorkLogRouteTransitionCubit>().markSettled();
      }
    });
  }

  @override
  void dispose() {
    _routeTransitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<WorkLogVehiclesCubit, WorkLogVehiclesState>(
        listenWhen: (previous, current) {
          final previousId = previous is WorkLogVehiclesLoaded
              ? previous.selectedVehicleId
              : null;
          final currentId = current is WorkLogVehiclesLoaded
              ? current.selectedVehicleId
              : null;
          return currentId != null && currentId != previousId;
        },
        listener: (context, state) {
          if (state case WorkLogVehiclesLoaded(:final selectedVehicleId?)) {
            context.read<WorkLogHistoryBloc>().add(
              WorkLogHistoryOpened(selectedVehicleId),
            );
          }
        },
        child: BlocBuilder<WorkLogVehiclesCubit, WorkLogVehiclesState>(
          builder: (context, vehiclesState) {
            final selectedVehicle = vehiclesState is WorkLogVehiclesLoaded
                ? vehiclesState.selectedVehicle
                : null;
            final mechanicMode = widget.launch is MechanicWorkLogLaunch;
            return Scaffold(
              backgroundColor: AmThemeColors.of(context).background,
              extendBodyBehindAppBar: true,
              appBar: switch (widget.launch) {
                OwnerWorkLogLaunch() => _OwnerHistoryAppBar(
                  state: vehiclesState,
                  routeAnimation: widget.routeAnimation,
                  onVehicleSelected: context
                      .read<WorkLogVehiclesCubit>()
                      .select,
                  onAddPressed: selectedVehicle == null
                      ? null
                      : () => _openWizard(selectedVehicle),
                ),
                MechanicWorkLogLaunch() => _MechanicHistoryAppBar(
                  title: selectedVehicle?.name ?? '',
                  onBackPressed: _close,
                  onNotificationsPressed: widget.onNotificationsPressed,
                ),
              },
              body: WorkLogHistoryEdge(
                backgroundColor: AmThemeColors.of(context).background,
                accentColor: AmThemeColors.of(context).accent,
                child: BlocBuilder<_WorkLogRouteTransitionCubit, bool>(
                  builder: (context, routeSettled) => routeSettled
                      ? _HistoryContent(
                          vehiclesState: vehiclesState,
                          onEntryPressed: _openDetail,
                        )
                      : const Center(
                          key: Key('work-log-route-transition-loading'),
                          child: CircularProgressIndicator(),
                        ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: mechanicMode && selectedVehicle != null
                  ? AmMainFab(
                      key: const Key('work-log-mechanic-fab'),
                      width: 280,
                      height: 54,
                      label: 'AGGIUNGI LAVORO',
                      color: AmThemeColors.of(context).accent,
                      onPressed: () => _openWizard(selectedVehicle),
                    )
                  : null,
            );
          },
        ),
      );

  void _close() {
    final callback = widget.onCloseRequested;
    if (callback != null) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _openWizard(
    WorkLogVehicle vehicle, {
    WorkLogType initialType = WorkLogType.other,
  }) async {
    final result = await _routeTransitions.push<WorkLogSaveResult>(
      Navigator.of(context, rootNavigator: true),
      builder: (_, _) => _WorkLogWizardPage(
        vehicle: vehicle,
        createWorkLog: CreateWorkLog(widget.dependencies.repository),
        initialType: initialType,
      ),
    );
    if (!mounted || result == null) return;
    context.read<WorkLogVehiclesCubit>().updateCurrentKm(
      result.vehicleId,
      result.serviceKm,
    );
    context.read<WorkLogHistoryBloc>().add(
      const WorkLogHistoryRefreshRequested(),
    );
  }

  Future<void> _openDetail(WorkLogEntry entry) {
    final vehiclesState = context.read<WorkLogVehiclesCubit>().state;
    final currentKm = vehiclesState is WorkLogVehiclesLoaded
        ? vehiclesState.selectedVehicle?.currentKm
        : null;
    final selectedVehicle = vehiclesState is WorkLogVehiclesLoaded
        ? vehiclesState.selectedVehicle
        : null;
    return _routeTransitions.push<void>(
      Navigator.of(context, rootNavigator: true),
      builder: (_, _) => WorkLogDetailPage(
        entry: entry,
        currentKm: currentKm,
        onAddPressed: selectedVehicle == null
            ? null
            : (type) => _openWizard(selectedVehicle, initialType: type),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.vehiclesState,
    required this.onEntryPressed,
  });

  final WorkLogVehiclesState vehiclesState;
  final ValueChanged<WorkLogEntry> onEntryPressed;

  @override
  Widget build(BuildContext context) => switch (vehiclesState) {
    WorkLogVehiclesLoading() => const Center(
      child: CircularProgressIndicator(),
    ),
    WorkLogVehiclesFailure(:final message) => _FeatureFailure(
      message: message,
      onRetry: context.read<WorkLogVehiclesCubit>().load,
    ),
    WorkLogVehiclesLoaded(:final vehicles, :final selectedVehicleId) =>
      vehicles.isEmpty || selectedVehicleId == null
          ? const Center(child: Text('Nessun veicolo disponibile'))
          : _HistoryList(onEntryPressed: onEntryPressed),
  };
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.onEntryPressed});

  final ValueChanged<WorkLogEntry> onEntryPressed;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<WorkLogHistoryBloc>();
    bloc.add(const WorkLogHistoryRefreshRequested());
    await bloc.stream.firstWhere(
      (state) =>
          state is WorkLogHistoryFailure ||
          state is WorkLogHistoryLoaded && !state.isRefreshing,
    );
  }

  bool _onScroll(BuildContext context, ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 480) {
      context.read<WorkLogHistoryBloc>().add(
        const WorkLogHistoryLoadMoreRequested(),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<WorkLogHistoryBloc, WorkLogHistoryState>(
        listenWhen: (previous, current) =>
            current is WorkLogHistoryLoaded &&
            current.refreshError != null &&
            (previous is! WorkLogHistoryLoaded ||
                previous.refreshError != current.refreshError),
        listener: (context, state) {
          if (state case WorkLogHistoryLoaded(:final refreshError?)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(refreshError)));
          }
        },
        builder: (context, state) => switch (state) {
          WorkLogHistoryLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          WorkLogHistoryFailure(:final message) => _FeatureFailure(
            message: message,
            onRetry: () => context.read<WorkLogHistoryBloc>().add(
              const WorkLogHistoryRefreshRequested(),
            ),
          ),
          WorkLogHistoryLoaded(:final entries, :final visibleEntries) =>
            NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _onScroll(context, notification),
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: Stack(
                  children: [
                    entries.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(
                                key: Key('work-log-history-top-spacing'),
                                height: 185,
                              ),
                              Center(child: Text('Nessun lavoro registrato')),
                            ],
                          )
                        : ListView.builder(
                            key: const Key('work-log-history-list'),
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                            itemCount: visibleEntries.length + 2,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return const SizedBox(
                                  key: Key('work-log-history-top-spacing'),
                                  height: 185,
                                );
                              }
                              final entryIndex = index - 1;
                              if (entryIndex == visibleEntries.length) {
                                if (visibleEntries.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 70),
                                    child: Center(
                                      child: Text(
                                        'Nessun lavoro per questo filtro',
                                      ),
                                    ),
                                  );
                                }
                                return SizedBox(
                                  key: const Key('work-log-page-loader'),
                                  height: 56,
                                  child: state.isLoadingMore
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : null,
                                );
                              }
                              final entry = visibleEntries[entryIndex];
                              return WorkLogItemCard(
                                key: ValueKey('work-log-item-${entry.id}'),
                                entry: entry,
                                entranceIndex: entryIndex,
                                onTap: () => onEntryPressed(entry),
                              );
                            },
                          ),
                    Positioned(
                      top: 125,
                      left: 20,
                      right: 20,
                      child: WorkLogHistoryFilter(
                        selectedType: state.selectedType,
                        onChanged: (type) => context
                            .read<WorkLogHistoryBloc>()
                            .add(WorkLogHistoryFilterSelected(type)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        },
      );
}

/// Impedisce che una risposta veloce costruisca la lista mentre il navigator
/// sta ancora animando la route. La query parte subito e il risultato resta nel
/// BLoC; al completamento della transizione viene pubblicata la UI gia pronta.
class _WorkLogRouteTransitionCubit extends Cubit<bool> {
  _WorkLogRouteTransitionCubit() : super(false);

  void markSettled() {
    if (!state) emit(true);
  }
}

class _OwnerHistoryAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const _OwnerHistoryAppBar({
    required this.state,
    required this.onVehicleSelected,
    required this.onAddPressed,
    this.routeAnimation,
  });

  final WorkLogVehiclesState state;
  final ValueChanged<String> onVehicleSelected;
  final VoidCallback? onAddPressed;
  final Listenable? routeAnimation;

  @override
  Size get preferredSize =>
      const Size.fromHeight(WorkLogTopAppBar.contentHeight);

  @override
  State<_OwnerHistoryAppBar> createState() => _OwnerHistoryAppBarState();
}

class _OwnerHistoryAppBarState extends State<_OwnerHistoryAppBar> {
  late final AmLiquidGlassRepaintController _glassRepaint;

  @override
  void initState() {
    super.initState();
    _glassRepaint = AmLiquidGlassRepaintController();
    _glassRepaint.bindExternalRepaint(widget.routeAnimation);
  }

  @override
  void didUpdateWidget(_OwnerHistoryAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeAnimation != widget.routeAnimation) {
      _glassRepaint.bindExternalRepaint(widget.routeAnimation);
    }
  }

  @override
  void dispose() {
    _glassRepaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return WorkLogTopAppBar(
      liquidGlassRepaint: _glassRepaint,
      liquidGlassGeneration: widget.routeAnimation,
      leadingWidth: null,
      leading: BlocBuilder<WorkLogVehiclesCubit, WorkLogVehiclesState>(
        builder: (context, state) => _VehicleDropdown(
          state: state,
          onVehicleSelected: widget.onVehicleSelected,
          liquidGlassRepaint: _glassRepaint,
        ),
      ),
      title: Text(
        'LAVORI',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      trailing: BlocBuilder<WorkLogVehiclesCubit, WorkLogVehiclesState>(
        builder: (context, state) {
          final vehicle = state is WorkLogVehiclesLoaded
              ? state.selectedVehicle
              : null;
          return Semantics(
            label: 'Aggiungi lavoro',
            button: true,
            enabled: vehicle != null,
            child: AmSoftButton(
              key: const Key('work-log-owner-add'),
              width: AmControlMetrics.circularButtonVisualSize,
              height: AmControlMetrics.circularButtonVisualSize,
              color: colors.accent,
              iconSize: AmControlMetrics.circularButtonIconSize,
              colorOpacity: 0.8,
              icon: HugeIcons.strokeRoundedAdd01,
              iconWeight: 2.8,
              liquidGlassEnabled: true,
              liquidGlassRepaint: _glassRepaint,
              onPressed: vehicle == null ? null : widget.onAddPressed,
            ),
          );
        },
      ),
    );
  }
}

class _VehicleDropdown extends StatelessWidget {
  const _VehicleDropdown({
    required this.state,
    required this.onVehicleSelected,
    required this.liquidGlassRepaint,
  });

  final WorkLogVehiclesState state;
  final ValueChanged<String> onVehicleSelected;
  final AmLiquidGlassRepaintController liquidGlassRepaint;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final WorkLogVehiclesLoaded? loaded = switch (state) {
      WorkLogVehiclesLoaded loaded => loaded,
      _ => null,
    };
    final selected = loaded?.selectedVehicle;
    return AmPullDownLG(
      key: const Key('work-log-owner-vehicle-selector'),
      brand: '',
      popupShadow: Theme.of(context).brightness == Brightness.light
          ? const BoxShadow(
              color: Colors.black12,
              blurRadius: 78,
              offset: Offset(0, 2),
            )
          : null,

      lable: selected == null
          ? 'VEICOLO'
          : (selected.name.isEmpty ? selected.plate : selected.name),
      backgroundColor: AmControlMetrics.pullDownFill(
        Theme.of(context).brightness,
      ),
      popupBackgroundColor: AmControlMetrics.pullDownPopupFill(
        Theme.of(context).brightness,
      ),
      buttonShadow: AmControlMetrics.pullDownShadow(
        Theme.of(context).brightness,
      ),
      liquidGlassEnabled: true,
      ownsLiquidGlassGroup: false,
      liquidGlassRepaint: liquidGlassRepaint,
      onTap: () {},
      larghezza: AmControlMetrics.pullDownWidth,
      popupBorderRadius: AmControlMetrics.pullDownRadius,
      buttonIcons: HugeIcons.strokeRoundedCar05,
      buttonIconsSize: AmControlMetrics.pullDownIconSize,
      iconColor: colors.textPrimary,
      textColor: colors.textPrimary,
      buttonLableStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      arrow: true,
      children: [
        for (final vehicle in loaded?.vehicles ?? const <WorkLogVehicle>[])
          ItemMorphPopUp(
            icon: HugeIcons.strokeRoundedCar05,
            text: vehicle.name.isEmpty
                ? vehicle.plate
                : vehicle.name.toUpperCase(),
            iconSize: AmControlMetrics.pullDownIconSize,
            iconColor: colors.info,
            textColor: colors.textPrimary,
            textSize: 14,
            textWeight: FontWeight.w600,
            iconsWheight: FontWeight.w900,
            onTap: () => onVehicleSelected(vehicle.id),
          ),
      ],
    );
  }
}

class _MechanicHistoryAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const _MechanicHistoryAppBar({
    required this.title,
    required this.onBackPressed,
    required this.onNotificationsPressed,
  });

  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback? onNotificationsPressed;

  @override
  Size get preferredSize =>
      const Size.fromHeight(WorkLogTopAppBar.contentHeight);

  @override
  State<_MechanicHistoryAppBar> createState() => _MechanicHistoryAppBarState();
}

class _MechanicHistoryAppBarState extends State<_MechanicHistoryAppBar> {
  late final AmLiquidGlassRepaintController _glassRepaint;

  @override
  void initState() {
    super.initState();
    _glassRepaint = AmLiquidGlassRepaintController();
  }

  @override
  void dispose() {
    _glassRepaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return WorkLogTopAppBar(
      liquidGlassRepaint: _glassRepaint,
      leading: AmSoftButton(
        key: const Key('work-log-mechanic-back'),
        width: AmControlMetrics.circularButtonVisualSize,
        height: AmControlMetrics.circularButtonVisualSize,
        iconSize: AmControlMetrics.circularButtonIconSize,
        color: colors.background.withValues(alpha: 0.3),
        icon: HugeIcons.strokeRoundedArrowLeft01,
        iconColor: colors.textPrimary,
        tooltip: 'Indietro',
        liquidGlassRepaint: _glassRepaint,
        onPressed: widget.onBackPressed,
      ),
      title: Text(
        widget.title.toUpperCase(),
        softWrap: true,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      trailing: AmSoftButton(
        key: const Key('work-log-mechanic-notifications'),
        width: AmControlMetrics.circularButtonVisualSize,
        height: AmControlMetrics.circularButtonVisualSize,
        iconSize: AmControlMetrics.circularButtonIconSize,
        color: colors.accent.withValues(alpha: 0.3),
        icon: HugeIcons.strokeRoundedNotification01,
        tooltip: 'Notifiche',
        liquidGlassRepaint: _glassRepaint,
        onPressed: widget.onNotificationsPressed,
      ),
    );
  }
}

class _WorkLogWizardPage extends StatelessWidget {
  const _WorkLogWizardPage({
    required this.vehicle,
    required this.createWorkLog,
    required this.initialType,
  });

  final WorkLogVehicle vehicle;
  final CreateWorkLog createWorkLog;
  final WorkLogType initialType;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WorkLogEditorCubit(createWorkLog: createWorkLog),
    child: Builder(
      builder: (context) {
        final colors = AmThemeColors.of(context);
        return Scaffold(
          backgroundColor: colors.background,
          resizeToAvoidBottomInset: false,
          appBar: WorkLogTopAppBar(
            leading: WorkLogGlassControl(
              child: AmSoftButton(
                key: const Key('work-log-wizard-back'),
                width: AmControlMetrics.circularButtonVisualSize,
                height: AmControlMetrics.circularButtonVisualSize,
                iconSize: AmControlMetrics.circularButtonIconSize,
                color: colors.background.withValues(alpha: 0.3),
                icon: HugeIcons.strokeRoundedArrowLeft01,
                iconColor: colors.textPrimary,
                tooltip: 'Indietro',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              'AGGIUNGI LAVORO',
              key: const Key('work-log-wizard-title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            trailing: const SizedBox.shrink(),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: WorkLogWizardBody(
              context: WorkLogLaunchContext(
                vehicleId: vehicle.id,
                vehicleName: vehicle.name,
                currentKm: vehicle.currentKm,
                initialWorkType: initialType.wireValue,
              ),
              cubit: context.read<WorkLogEditorCubit>(),
              onSaved: (result) => Navigator.of(context).pop(result),
            ),
          ),
        );
      },
    ),
  );
}

class _FeatureFailure extends StatelessWidget {
  const _FeatureFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        AmMainFab(
          width: 180,
          height: 48,
          label: 'RIPROVA',
          color: AmThemeColors.of(context).accent,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
