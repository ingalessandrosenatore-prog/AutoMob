import 'dart:io';

import 'package:equatable/equatable.dart';

sealed class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Carica (o ricarica) tutti i dati visualizzati nella dashboard.
/// Per ora: solo i veicoli. In futuro qui aggiungeremo KPI, prossime scadenze, alert ecc.
class LoadDashboardData extends DashboardEvent {}

class DashboardPageChanged extends DashboardEvent {
  final int newIndex;
  DashboardPageChanged(this.newIndex);
}

/// Pull-to-refresh esplicito: ricarica i veicoli SENZA passare per
/// DashboardLoading, cosi' vehicles/kpis restano visibili durante il
/// refresh invece di far comparire il pop-up di caricamento a tutto schermo.
class DashboardRefreshRequested extends DashboardEvent {}

/// Richiesta di aggiornare la foto del veicolo (menu "MODIFICA FOTO" sulla
/// card veicolo). Ricarica la dashboard al termine se il salvataggio riesce.
class VehiclePhotoUpdateRequested extends DashboardEvent {
  final String targa;
  final File foto;

  VehiclePhotoUpdateRequested({required this.targa, required this.foto});

  @override
  List<Object?> get props => [targa, foto.path];
}