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
import '../../domain/usecases/get_fuel_cost_for_period.dart';
import '../../domain/entities/maintenance_cost_period.dart';
import '../../domain/usecases/assign_workshop_mascots.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetVehicles getVehicles;
  final ComputeMaintenanceKpis computeKpis;
  final UpdateVehiclePhoto updateVehiclePhoto;
  final CalculateMaintenanceCost calculateMaintenanceCost;
  final GetFuelCostForPeriod getFuelCostForPeriod;
  final GetLatestOpenFutureWorks getLatestOpenFutureWorks;
  final AssignWorkshopMascots assignWorkshopMascots;

  DashboardBloc({
    required this.getVehicles,
    required this.computeKpis,
    required this.updateVehiclePhoto,
    required this.calculateMaintenanceCost,
    required this.getFuelCostForPeriod,
    required this.getLatestOpenFutureWorks,
    AssignWorkshopMascots? assignWorkshopMascots,
  }) : assignWorkshopMascots = assignWorkshopMascots ?? AssignWorkshopMascots(),
       super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<DashboardPageChanged>(_onVehicleChange);
    on<WorkshopPageChanged>(_onWorkshopChange);
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
        fuelCostCents: getFuelCostForPeriod(
          lista.first,
          MaintenanceCostPeriod.monthly,
        ),
        futureWorksByVehicleId: _groupFutureWorks(
          futureWorksResult.toNullable()!,
        ),
        workshopMascotsByVehicleId: assignWorkshopMascots(lista),
        workshopIndexByVehicleId: {
          for (final vehicle in lista)
            vehicle.id: vehicle.mechanics.isEmpty ? 0 : 1,
        },
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
    // Durante la rete l'utente può cambiare veicolo o officina: conserva
    // la selezione più recente, non quella fotografata prima dell'attesa.
    final latest = state is DashboardLoaded
        ? state as DashboardLoaded
        : current;
    if (vehiclesResult.isLeft() || futureWorksResult.isLeft()) {
      emit(latest.copyWith(isRefreshing: false));
      return;
    }

    final vehicles = vehiclesResult.toNullable()!;
    final lista = vehicles.isEmpty ? [Vehicle.placeholder()] : vehicles;
    final selectedIndex = _selectedIndexAfterReload(latest, lista);
    emit(
      DashboardLoaded(
        vehicles: lista,
        index: selectedIndex,
        kpis: computeKpis(lista[selectedIndex]),
        isRefreshing: false,
        costPeriod: latest.costPeriod,
        maintenanceCostCents: calculateMaintenanceCost(
          lista[selectedIndex],
          latest.costPeriod,
        ),
        fuelCostCents: getFuelCostForPeriod(
          lista[selectedIndex],
          latest.costPeriod,
        ),
        futureWorksByVehicleId: _groupFutureWorks(
          futureWorksResult.toNullable()!,
        ),
        workshopMascotsByVehicleId: assignWorkshopMascots(lista),
        workshopIndexByVehicleId: _workshopIndexesAfterReload(latest, lista),
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
          fuelCostCents: current.fuelCostCents,
          futureWorksByVehicleId: current.futureWorksByVehicleId,
          workshopMascotsByVehicleId: current.workshopMascotsByVehicleId,
          workshopIndexByVehicleId: current.workshopIndexByVehicleId,
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
              fuelCostCents: current.fuelCostCents,
              futureWorksByVehicleId: current.futureWorksByVehicleId,
              workshopMascotsByVehicleId: current.workshopMascotsByVehicleId,
              workshopIndexByVehicleId: current.workshopIndexByVehicleId,
              photoUpdateError: failure.message,
            ),
          ),
          (vehicles) {
            final lista = vehicles.isEmpty ? [Vehicle.placeholder()] : vehicles;
            final idx = _selectedIndexAfterReload(current, lista);
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
                fuelCostCents: getFuelCostForPeriod(
                  lista[idx],
                  current.costPeriod,
                ),
                futureWorksByVehicleId: current.futureWorksByVehicleId,
                workshopMascotsByVehicleId: assignWorkshopMascots(lista),
                workshopIndexByVehicleId: _workshopIndexesAfterReload(
                  current,
                  lista,
                ),
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
          fuelCostCents: getFuelCostForPeriod(
            veicoloSelezionato,
            currentState.costPeriod,
          ),
        ),
      );
    }
  }

  void _onWorkshopChange(
    WorkshopPageChanged event,
    Emitter<DashboardState> emit,
  ) {
    final current = state;
    if (current is! DashboardLoaded) return;
    final vehicle = current.vehicles
        .where((v) => v.id == event.vehicleId)
        .firstOrNull;
    if (vehicle == null ||
        event.index < 0 ||
        event.index > vehicle.mechanics.length) {
      return;
    }
    emit(
      current.copyWith(
        workshopIndexByVehicleId: {
          ...current.workshopIndexByVehicleId,
          event.vehicleId: event.index,
        },
      ),
    );
  }

  Map<String, int> _workshopIndexesAfterReload(
    DashboardLoaded current,
    List<Vehicle> vehicles,
  ) => {
    for (final vehicle in vehicles)
      vehicle.id: _workshopIndexAfterReload(current, vehicle),
  };

  int _workshopIndexAfterReload(DashboardLoaded current, Vehicle vehicle) {
    final index = current.workshopIndexByVehicleId[vehicle.id];
    if (index == 0 || vehicle.mechanics.isEmpty) return 0;
    final previous = current.vehicles
        .where((v) => v.id == vehicle.id)
        .firstOrNull;
    if (index == null ||
        previous == null ||
        index > previous.mechanics.length) {
      return 1;
    }
    // L'identità resiste al riordino del server; l'indice da solo no.
    final id = previous.mechanics[index - 1].id;
    final next = vehicle.mechanics.indexWhere((mechanic) => mechanic.id == id);
    return next < 0 ? index.clamp(1, vehicle.mechanics.length) : next + 1;
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
        fuelCostCents: getFuelCostForPeriod(
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

  int _selectedIndexAfterReload(
    DashboardLoaded current,
    List<Vehicle> reloadedVehicles,
  ) {
    if (current.vehicles.isEmpty || current.index >= current.vehicles.length) {
      return 0;
    }

    // L'indice e' solo una posizione UI: dopo una nuova query l'ordine puo'
    // cambiare. L'identita' del veicolo e' l'unico riferimento stabile.
    final selectedVehicleId = current.vehicles[current.index].id;
    final reloadedIndex = reloadedVehicles.indexWhere(
      (vehicle) => vehicle.id == selectedVehicleId,
    );
    return reloadedIndex < 0 ? 0 : reloadedIndex;
  }
}
