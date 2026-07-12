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

  /// true durante un pull-to-refresh esplicito (DashboardRefreshRequested):
  /// a differenza del caricamento iniziale (DashboardLoading), qui si resta
  /// su DashboardLoaded per tutta la durata -- vehicles/kpis restano
  /// visibili finche' non arrivano i nuovi dati, niente pop-up modale.
  final bool isRefreshing;

  /// Messaggio d'errore "one-shot" del solo aggiornamento foto (menu MODIFICA
  /// FOTO). Non e' preservato da [copyWith]: viene consumato dalla UI (dialog)
  /// e sparisce alla emissione successiva. Null = nessun errore.
  final String? photoUpdateError;

  DashboardLoaded({
    required this.vehicles,
    required this.index,
    required this.kpis,
    this.isRefreshing = false,
    this.photoUpdateError,
  });

  DashboardLoaded copyWith({
    List<Vehicle>? vehicles,
    int? index,
    List<MaintenanceKpi>? kpis,
    bool? isRefreshing,
  }) {
    return DashboardLoaded(
      vehicles: vehicles ?? this.vehicles,
      index: index ?? this.index,
      kpis: kpis ?? this.kpis,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      // photoUpdateError NON viene propagato: e' un errore one-shot.
    );
  }

  @override
  List<Object?> get props => [vehicles, index, kpis, isRefreshing, photoUpdateError];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
