import 'dart:async';

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_feature_contract.dart';
import '../domain/work_log_launch_context.dart';
import '../domain/work_log_use_cases.dart';
import '../domain/work_log_vehicle.dart';
import 'work_log_bloc.dart';
import 'work_log_detail_body.dart';
import 'work_log_editor_cubit.dart';
import 'work_log_item_card.dart';
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
  });

  final WorkLogLaunch launch;
  final WorkLogDependencies dependencies;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCloseRequested;

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
  });

  final WorkLogLaunch launch;
  final WorkLogDependencies dependencies;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onCloseRequested;

  @override
  State<_WorkLogFeatureView> createState() => _WorkLogFeatureViewState();
}

class _WorkLogFeatureViewState extends State<_WorkLogFeatureView> {
  ModalRoute<dynamic>? _boundRoute;
  Timer? _routeTransitionTimer;

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
              body: BlocBuilder<_WorkLogRouteTransitionCubit, bool>(
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
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.miniEndFloat,
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

  Future<void> _openWizard(WorkLogVehicle vehicle) async {
    final result = await Navigator.of(context, rootNavigator: true)
        .push<WorkLogSaveResult>(
          MaterialPageRoute(
            builder: (_) => _WorkLogWizardPage(
              vehicle: vehicle,
              createWorkLog: CreateWorkLog(widget.dependencies.repository),
            ),
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

  Future<void> _openDetail(WorkLogEntry entry) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(builder: (_) => _WorkLogDetailPage(entry: entry)),
      );
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
          WorkLogHistoryLoaded(:final entries) =>
            NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _onScroll(context, notification),
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: entries.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Center(child: Text('Nessun lavoro registrato')),
                        ],
                      )
                    : ListView.builder(
                        key: const Key('work-log-history-list'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount:
                            entries.length + 1 + (state.hasReachedMax ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const SizedBox(
                              key: Key('work-log-history-top-spacing'),
                              height: 200,
                            );
                          }
                          final entryIndex = index - 1;
                          if (entryIndex == entries.length) {
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
                          final entry = entries[entryIndex];
                          return WorkLogItemCard(
                            entry: entry,
                            onTap: () => onEntryPressed(entry),
                          );
                        },
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

class _OwnerHistoryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _OwnerHistoryAppBar({
    required this.state,
    required this.onVehicleSelected,
    required this.onAddPressed,
  });

  final WorkLogVehiclesState state;
  final ValueChanged<String> onVehicleSelected;
  final VoidCallback? onAddPressed;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return OCLiquidGlassGroup(
      settings: const OCLiquidGlassSettings(
        refractStrength: -0.08,
        blurRadiusPx: 2,
        specStrength: 1,
        specWidth: 0.5,
        specAngle: 145,
        specPower: 10,
        lightbandOffsetPx: 7,
        lightbandStrength: 0.5,
      ),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<WorkLogVehiclesCubit, WorkLogVehiclesState>(
              builder: (context, state) => _VehicleDropdown(
                state: state,
                onVehicleSelected: onVehicleSelected,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'LAVORI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: BlocBuilder<WorkLogVehiclesCubit, WorkLogVehiclesState>(
                builder: (context, state) {
                  final vehicle = state is WorkLogVehiclesLoaded
                      ? state.selectedVehicle
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AmSoftButton(
                      key: const Key('work-log-owner-add'),
                      width: 45,
                      height: 45,
                      color: colors.accent,
                      iconColor: colors.textPrimary,
                      icon: HugeIcons.strokeRoundedAdd01,
                      tooltip: 'Aggiungi lavoro',
                      liquidGlassEnabled: true,
                      onPressed: vehicle == null ? null : onAddPressed,
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

class _VehicleDropdown extends StatelessWidget {
  const _VehicleDropdown({
    required this.state,
    required this.onVehicleSelected,
  });

  final WorkLogVehiclesState state;
  final ValueChanged<String> onVehicleSelected;

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
      lable: selected == null
          ? 'VEICOLO'
          : (selected.name.isEmpty ? selected.plate : selected.name),
      backgroundColor: colors.background.withValues(alpha: 0.3),
      popupBackgroundColor: colors.background.withValues(alpha: 0.8),
      liquidGlassEnabled: true,
      onTap: () {},
      larghezza: 280,
      buttonIcons: HugeIcons.strokeRoundedCar05,
      buttonIconsSize: 20,
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
            text: vehicle.name.isEmpty ? vehicle.plate : vehicle.name,
            iconSize: 20,
            iconColor: colors.info,
            textColor: colors.textPrimary,
            onTap: () => onVehicleSelected(vehicle.id),
          ),
      ],
    );
  }
}

class _MechanicHistoryAppBar extends StatelessWidget
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
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return OCLiquidGlassGroup(
      settings: const OCLiquidGlassSettings(
        refractStrength: -0.08,
        blurRadiusPx: 2,
        specStrength: 1,
        specWidth: 0.5,
        specAngle: 145,
        specPower: 10,
        lightbandOffsetPx: 7,
        lightbandStrength: 0.5,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: AmSoftButton(
                key: const Key('work-log-mechanic-back'),
                width: 48,
                height: 48,
                color: colors.background.withValues(alpha: 0.3),
                icon: HugeIcons.strokeRoundedArrowLeft01,
                iconColor: colors.textPrimary,
                tooltip: 'Indietro',
                onPressed: onBackPressed,
              ),
            ),
            Expanded(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AmSoftButton(
                key: const Key('work-log-mechanic-notifications'),
                width: 48,
                height: 48,
                color: colors.background.withValues(alpha: 0.3),
                icon: HugeIcons.strokeRoundedNotification01,
                iconColor: colors.textPrimary,
                tooltip: 'Notifiche',
                onPressed: onNotificationsPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkLogWizardPage extends StatelessWidget {
  const _WorkLogWizardPage({
    required this.vehicle,
    required this.createWorkLog,
  });

  final WorkLogVehicle vehicle;
  final CreateWorkLog createWorkLog;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => WorkLogEditorCubit(createWorkLog: createWorkLog),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: AmThemeColors.of(context).background,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: WorkLogWizardBody(
            context: WorkLogLaunchContext(
              vehicleId: vehicle.id,
              vehicleName: vehicle.name,
              currentKm: vehicle.currentKm,
            ),
            cubit: context.read<WorkLogEditorCubit>(),
            onSaved: (result) => Navigator.of(context).pop(result),
          ),
        ),
      ),
    ),
  );
}

class _WorkLogDetailPage extends StatelessWidget {
  const _WorkLogDetailPage({required this.entry});

  final WorkLogEntry entry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AmThemeColors.of(context).background,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: AmSoftButton(
                key: const Key('work-log-detail-back'),
                width: 48,
                height: 48,
                color: AmThemeColors.of(
                  context,
                ).surfaceRaised.withValues(alpha: .24),
                icon: HugeIcons.strokeRoundedArrowLeft01,
                tooltip: 'Indietro',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Expanded(child: WorkLogDetailBody(entry: entry)),
        ],
      ),
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
