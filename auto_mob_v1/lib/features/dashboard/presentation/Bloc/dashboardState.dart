import 'package:equatable/equatable.dart';

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

  DashboardLoaded({required this.vehicles, required this.index});

  DashboardLoaded copyWith({
    List<Vehicle>? vehicles,
    int? index,}) {
    return DashboardLoaded(
      vehicles: vehicles ?? this.vehicles,
      index: index ?? this.index,
    );
  }

  @override
  List<Object?> get props => [vehicles, index];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
