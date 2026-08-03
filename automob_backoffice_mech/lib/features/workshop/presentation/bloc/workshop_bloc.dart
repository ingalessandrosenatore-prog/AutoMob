import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/workshop_catalog.dart';
import '../../domain/usecases/get_workshop_catalog.dart';
import 'workshop_event.dart';
import 'workshop_state.dart';

class WorkshopBloc extends Bloc<WorkshopEvent, WorkshopState> {
  WorkshopBloc({required this.getWorkshopCatalog})
    : super(const WorkshopInitial()) {
    on<WorkshopStarted>(_onStarted);
    on<WorkshopRetryRequested>(_onRetryRequested);
    on<WorkshopSearchChanged>(_onSearchChanged);
    on<WorkshopVisibleWindowRequested>(_onVisibleWindowRequested);
  }

  final GetWorkshopCatalog getWorkshopCatalog;

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

  Future<void> _load(Emitter<WorkshopState> emit) async {
    emit(const WorkshopLoading());
    final result = await getWorkshopCatalog();
    result.match(
      (failure) => emit(WorkshopLoadFailure(failure.message)),
      (catalog) => emit(
        WorkshopReady(
          mechanic: catalog.mechanic,
          allVehicles: catalog.vehicles,
          filteredVehicles: catalog.vehicles,
          query: '',
          visibleCount: WorkshopReady.pageSize,
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
    final tokens = _normalize(
      query,
    ).split(' ').where((token) => token.isNotEmpty).toList(growable: false);
    final filtered = tokens.isEmpty
        ? current.allVehicles
        : current.allVehicles
              .where((vehicle) {
                final searchable = _searchableText(vehicle);
                return tokens.every(searchable.contains);
              })
              .toList(growable: false);
    emit(
      current.copyWith(
        filteredVehicles: filtered,
        query: query,
        visibleCount: WorkshopReady.pageSize,
      ),
    );
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
