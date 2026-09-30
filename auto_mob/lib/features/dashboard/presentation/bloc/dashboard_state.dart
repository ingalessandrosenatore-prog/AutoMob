import 'package:equatable/equatable.dart';

import '../../../vehicle/domain/entities/maintenance_kpi.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../future_work/domain/entities/future_work_summary.dart';
import '../../domain/entities/maintenance_cost_period.dart';
import '../../domain/entities/workshop_mascot.dart';

sealed class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

/// Snapshot completo dei dati visualizzati nella dashboard.
/// Per ora contiene solo `vehicles`. In futuro aggiungeremo qui:
///   - kpis (calcoli per ogni veicolo)
///   - upcomingDeadlines (revisioni, tagliandi imminenti)
///   - alerts
class DashboardLoaded extends DashboardState {
  final List<Vehicle> vehicles;
  final int index;

  /// KPI di manutenzione del veicolo ATTUALMENTE selezionato (vehicles[index]).
  /// Vengono ricalcolati dal BLoC al caricamento e ad ogni cambio pagina.
  final List<MaintenanceKpi> kpis;

  /// true durante un pull-to-refresh esplicito (DashboardRefreshRequested):
  /// a differenza del caricamento iniziale (DashboardLoading), qui si resta
  /// su DashboardLoaded per tutta la durata -- vehicles/kpis restano
  /// visibili finche' non arrivano i nuovi dati, niente pop-up modale.
  final bool isRefreshing;

  /// Messaggio d'errore "one-shot" del solo aggiornamento foto (menu MODIFICA
  /// FOTO). Non e' preservato da [copyWith]: viene consumato dalla UI (dialog)
  /// e sparisce alla emissione successiva. Null = nessun errore.
  final String? photoUpdateError;
  final MaintenanceCostPeriod costPeriod;
  final int maintenanceCostCents;
  final int fuelCostCents;
  final Map<String, List<FutureWorkSummary>> futureWorksByVehicleId;
  final Map<String, List<WorkshopMascot>> workshopMascotsByVehicleId;
  final Map<String, int> workshopIndexByVehicleId;

  List<FutureWorkSummary> get selectedVehicleFutureWorks {
    if (vehicles.isEmpty || index >= vehicles.length) return const [];
    return futureWorksByVehicleId[vehicles[index].id] ?? const [];
  }

  DashboardLoaded({
    required this.vehicles,
    required this.index,
    required this.kpis,
    this.isRefreshing = false,
    this.photoUpdateError,
    this.costPeriod = MaintenanceCostPeriod.monthly,
    this.maintenanceCostCents = 0,
    this.fuelCostCents = 0,
    this.futureWorksByVehicleId = const {},
    this.workshopMascotsByVehicleId = const {},
    this.workshopIndexByVehicleId = const {},
  });

  DashboardLoaded copyWith({
    List<Vehicle>? vehicles,
    int? index,
    List<MaintenanceKpi>? kpis,
    bool? isRefreshing,
    MaintenanceCostPeriod? costPeriod,
    int? maintenanceCostCents,
    int? fuelCostCents,
    Map<String, List<FutureWorkSummary>>? futureWorksByVehicleId,
    Map<String, List<WorkshopMascot>>? workshopMascotsByVehicleId,
    Map<String, int>? workshopIndexByVehicleId,
  }) {
    return DashboardLoaded(
      vehicles: vehicles ?? this.vehicles,
      index: index ?? this.index,
      kpis: kpis ?? this.kpis,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      costPeriod: costPeriod ?? this.costPeriod,
      maintenanceCostCents: maintenanceCostCents ?? this.maintenanceCostCents,
      fuelCostCents: fuelCostCents ?? this.fuelCostCents,
      futureWorksByVehicleId:
          futureWorksByVehicleId ?? this.futureWorksByVehicleId,
      workshopMascotsByVehicleId:
          workshopMascotsByVehicleId ?? this.workshopMascotsByVehicleId,
      workshopIndexByVehicleId:
          workshopIndexByVehicleId ?? this.workshopIndexByVehicleId,
      // photoUpdateError NON viene propagato: e' un errore one-shot.
    );
  }

  @override
  List<Object?> get props => [
    vehicles,
    index,
    kpis,
    isRefreshing,
    photoUpdateError,
    costPeriod,
    maintenanceCostCents,
    fuelCostCents,
    futureWorksByVehicleId,
    workshopMascotsByVehicleId,
    workshopIndexByVehicleId,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
