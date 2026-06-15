import 'package:equatable/equatable.dart';

import '../../../vehicle/domain/entities/maintenance_kpi.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

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

  DashboardLoaded({
    required this.vehicles,
    required this.index,
    required this.kpis,
  });

  DashboardLoaded copyWith({
    List<Vehicle>? vehicles,
    int? index,
    List<MaintenanceKpi>? kpis,
  }) {
    return DashboardLoaded(
      vehicles: vehicles ?? this.vehicles,
      index: index ?? this.index,
      kpis: kpis ?? this.kpis,
    );
  }

  @override
  List<Object?> get props => [vehicles, index, kpis];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
