import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_catalog.dart';
import '../../domain/usecases/get_workshop_catalog.dart';
import 'workshop_event.dart';
import 'workshop_state.dart';
import 'workshop_vehicle_filter.dart';

class WorkshopBloc extends Bloc<WorkshopEvent, WorkshopState> {
  WorkshopBloc({required this.getWorkshopCatalog})
    : super(const WorkshopInitial()) {
    on<WorkshopStarted>(_onStarted);
    on<WorkshopRetryRequested>(_onRetryRequested);
    on<WorkshopWorkSaved>((_, emit) => _load(emit, keepFilters: true));
    on<WorkshopSearchChanged>(_onSearchChanged);
    on<WorkshopVehicleFilterChanged>(_onVehicleFilterChanged);
    on<WorkshopVisibleWindowRequested>(_onVisibleWindowRequested);
  }

  final GetWorkshopCatalog getWorkshopCatalog;
  int _loadVersion = 0;

  Future<void> _onStarted(
    WorkshopStarted event,
    Emitter<WorkshopState> emit,
  ) async {
    if (state is! WorkshopInitial) return;
    await _load(emit);
  }

  Future<void> _onRetryRequested(
    WorkshopRetryRequested event,
    Emitter<WorkshopState> emit,
  ) => _load(emit);

  Future<void> _load(
    Emitter<WorkshopState> emit, {
    bool keepFilters = false,
  }) async {
    final loadVersion = ++_loadVersion;
    if (!keepFilters || state is! WorkshopReady) emit(const WorkshopLoading());
    final result = await getWorkshopCatalog();
    if (loadVersion != _loadVersion) return;

    final current = state;
    final ready = keepFilters && current is WorkshopReady ? current : null;
    final query = ready?.query ?? '';
    final filter = ready?.filter ?? WorkshopVehicleFilter.all;
    result.match(
      (failure) => emit(WorkshopLoadFailure(failure.message)),
      (catalog) => emit(
        WorkshopReady(
          mechanic: catalog.mechanic,
          allVehicles: catalog.vehicles,
          filteredVehicles: _applyFilters(catalog.vehicles, query, filter),
          query: query,
          filter: filter,
          visibleCount: ready?.visibleCount ?? WorkshopReady.pageSize,
        ),
      ),
    );
  }

  void _onSearchChanged(
    WorkshopSearchChanged event,
    Emitter<WorkshopState> emit,
  ) {
    final current = state;
    if (current is! WorkshopReady) return;
    final query = event.query.trim();
    final filtered = _applyFilters(current.allVehicles, query, current.filter);
    emit(
      current.copyWith(
        filteredVehicles: filtered,
        query: query,
        visibleCount: WorkshopReady.pageSize,
      ),
    );
  }

  void _onVehicleFilterChanged(
    WorkshopVehicleFilterChanged event,
    Emitter<WorkshopState> emit,
  ) {
    final current = state;
    if (current is! WorkshopReady || current.filter == event.filter) return;
    emit(
      current.copyWith(
        filteredVehicles: _applyFilters(
          current.allVehicles,
          current.query,
          event.filter,
        ),
        filter: event.filter,
        visibleCount: WorkshopReady.pageSize,
      ),
    );
  }

  List<WorkshopVehicle> _applyFilters(
    List<WorkshopVehicle> vehicles,
    String query,
    WorkshopVehicleFilter filter,
  ) {
    final tokens = _normalize(
      query,
    ).split(' ').where((token) => token.isNotEmpty).toList(growable: false);
    return vehicles
        .where((vehicle) {
          final matchesQuery =
              tokens.isEmpty || tokens.every(_searchableText(vehicle).contains);
          final matchesStatus = switch (filter) {
            WorkshopVehicleFilter.all => true,
            WorkshopVehicleFilter.connected => !vehicle.hasPendingWorks,
            WorkshopVehicleFilter.maintenanceDue => vehicle.hasPendingWorks,
          };
          return matchesQuery && matchesStatus;
        })
        .toList(growable: false);
  }

  void _onVisibleWindowRequested(
    WorkshopVisibleWindowRequested event,
    Emitter<WorkshopState> emit,
  ) {
    final current = state;
    if (current is! WorkshopReady ||
        event.expectedVisibleCount != current.visibleCount ||
        !current.hasMore) {
      return;
    }
    emit(
      current.copyWith(
        visibleCount: (current.visibleCount + WorkshopReady.pageSize).clamp(
          0,
          current.filteredVehicles.length,
        ),
      ),
    );
  }

  String _searchableText(WorkshopVehicle vehicle) => _normalize(
    '${vehicle.brand} ${vehicle.model} ${vehicle.displayName} ${vehicle.plate}',
  );

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
