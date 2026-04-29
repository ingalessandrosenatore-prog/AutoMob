import 'package:equatable/equatable.dart';

sealed class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Carica (o ricarica) tutti i dati visualizzati nella dashboard.
/// Per ora: solo i veicoli. In futuro qui aggiungeremo KPI, prossime scadenze, alert ecc.
class LoadDashboardData extends DashboardEvent {}
