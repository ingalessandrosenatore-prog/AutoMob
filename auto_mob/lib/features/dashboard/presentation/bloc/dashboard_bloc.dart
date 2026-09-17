import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/domain/usecases/compute_maintenance_kpis.dart';
import '../../../vehicle/domain/usecases/get_vehicles.dart';
import '../../../vehicle/domain/usecases/update_vehicle_photo.dart';
import '../../../future_work/domain/entities/future_work_summary.dart';
import '../../../future_work/domain/usecases/get_latest_open_future_works.dart';
import '../../domain/usecases/calculate_maintenance_cost.dart';
import '../../domain/entities/maintenance_cost_period.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetVehicles getVehicles;
  final ComputeMaintenanceKpis computeKpis;
  final UpdateVehiclePhoto updateVehiclePhoto;
  final CalculateMaintenanceCost calculateMaintenanceCost;
  final GetLatestOpenFutureWorks getLatestOpenFutureWorks;

  DashboardBloc({
    required this.getVehicles,
    required this.computeKpis,
    required this.updateVehiclePhoto,
    required this.calculateMaintenanceCost,
    required this.getLatestOpenFutureWorks,
  }) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<DashboardPageChanged>(_onVehicleChange);
    on<DashboardCostPeriodChanged>(_onCostPeriodChange);
    on<VehiclePhotoUpdateRequested>(_onVehiclePhotoUpdateRequested);
    on<DashboardRefreshRequested>(
      _onDashboardRefreshRequested,
      transformer: droppable(),
    );
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    final vehiclesResult = await getVehicles();
    final vehicleFailure = vehiclesResult.getLeft().toNullable();
    if (vehicleFailure != null) {
      emit(DashboardError(message: vehicleFailure.message));
      return;
    }

    final futureWorksResult = await getLatestOpenFutureWorks();
    final futureWorksFailure = futureWorksResult.getLeft().toNullable();
    if (futureWorksFailure != null) {
      emit(DashboardError(message: futureWorksFailure.message));
      return;
    }

    final vehicles = vehiclesResult.toNullable()!;
    final lista = vehicles.isEmpty ? [Vehicle.placeholder()] : vehicles;
    emit(
      DashboardLoaded(
        vehicles: lista,
        index: 0,
        kpis: computeKpis(lista.first),
        maintenanceCostCents: calculateMaintenanceCost(
          lista.first,
          MaintenanceCostPeriod.monthly,
        ),
        futureWorksByVehicleId: _groupFutureWorks(
          futureWorksResult.toNullable()!,
        ),
      ),
    );
  }

  /// Pull-to-refresh: ricarica i veicoli restando su DashboardLoaded per
  /// tutta la durata (mai DashboardLoading) -- vehicles/kpis restano
  /// visibili finche' non arrivano i nuovi dati, cosi' l'indicatore di
  /// refresh inline non fa comparire il pop-up di caricamento a tutto schermo.
  Future<void> _onDashboardRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    emit(current.copyWith(isRefreshing: true));

    final vehiclesResult = await getVehicles();
    final futureWorksResult = await getLatestOpenFutureWorks();
    if (vehiclesResult.isLeft() || futureWorksResult.isLeft()) {
      emit(current.copyWith(isRefreshing: false));
      return;
    }

    final vehicles = vehiclesResult.toNullable()!;
    final lista = vehicles.isEmpty ? [Vehicle.placeholder()] : vehicles;
    emit(
      DashboardLoaded(
        vehicles: lista,
        index: 0,
        kpis: computeKpis(lista.first),
        isRefreshing: false,
        costPeriod: current.costPeriod,
        maintenanceCostCents: calculateMaintenanceCost(
          lista.first,
          current.costPeriod,
        ),
        futureWorksByVehicleId: _groupFutureWorks(
          futureWorksResult.toNullable()!,
        ),
      ),
    );
  }

  /// Aggiornamento foto: NON passa da DashboardLoading (che mostrerebbe il
  /// pop-up di caricamento a tutto schermo sopra la home e, smontando il
  /// carosello, farebbe cadere il popup "MODIFICA FOTO"). Sul modello del
  /// pull-to-refresh resta su DashboardLoaded, ricarica i veicoli e preserva
  /// l'indice del veicolo che si stava guardando. In errore lo comunica alla
  /// UI via photoUpdateError invece di ingoiarlo in silenzio.
  Future<void> _onVehiclePhotoUpdateRequested(
    VehiclePhotoUpdateRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    final result = await updateVehiclePhoto(
      targa: event.targa,
      foto: event.foto,
    );

    await result.fold(
      (failure) async => emit(
        DashboardLoaded(
          vehicles: current.vehicles,
          index: current.index,
          kpis: current.kpis,
          costPeriod: current.costPeriod,
          maintenanceCostCents: current.maintenanceCostCents,
          futureWorksByVehicleId: current.futureWorksByVehicleId,
          photoUpdateError: failure.message,
        ),
      ),
      (_) async {
        final reload = await getVehicles();
        reload.fold(
          (failure) => emit(
            DashboardLoaded(
              vehicles: current.vehicles,
              index: current.index,
              kpis: current.kpis,
              costPeriod: current.costPeriod,
              maintenanceCostCents: current.maintenanceCostCents,
              futureWorksByVehicleId: current.futureWorksByVehicleId,
              photoUpdateError: failure.message,
            ),
          ),
          (vehicles) {
            final lista = vehicles.isEmpty ? [Vehicle.placeholder()] : vehicles;
            final idx = current.index < lista.length ? current.index : 0;
            emit(
              DashboardLoaded(
                vehicles: lista,
                index: idx,
                kpis: computeKpis(lista[idx]),
                costPeriod: current.costPeriod,
                maintenanceCostCents: calculateMaintenanceCost(
                  lista[idx],
                  current.costPeriod,
                ),
                futureWorksByVehicleId: current.futureWorksByVehicleId,
              ),
            );
          },
        );
      },
    );
  }

  FutureOr<void> _onVehicleChange(
    DashboardPageChanged event,
    Emitter<DashboardState> emit,
  ) {
    final currentState = state;
    if (currentState is DashboardLoaded) {
      final veicoloSelezionato = currentState.vehicles[event.newIndex];
      // Cambiando veicolo ricalcolo i suoi KPI.
      emit(
        currentState.copyWith(
          index: event.newIndex,
          kpis: computeKpis(veicoloSelezionato),
          maintenanceCostCents: calculateMaintenanceCost(
            veicoloSelezionato,
            currentState.costPeriod,
          ),
        ),
      );
    }
  }

  void _onCostPeriodChange(
    DashboardCostPeriodChanged event,
    Emitter<DashboardState> emit,
  ) {
    final current = state;
    if (current is! DashboardLoaded) return;
    emit(
      current.copyWith(
        costPeriod: event.period,
        maintenanceCostCents: calculateMaintenanceCost(
          current.vehicles[current.index],
          event.period,
        ),
      ),
    );
  }

  Map<String, List<FutureWorkSummary>> _groupFutureWorks(
    List<FutureWorkSummary> items,
  ) {
    final grouped = <String, List<FutureWorkSummary>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.vehicleId, () => []).add(item);
    }
    return grouped;
  }
}
