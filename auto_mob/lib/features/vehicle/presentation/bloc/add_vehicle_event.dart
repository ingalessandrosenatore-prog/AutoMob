import 'dart:io';

import 'package:equatable/equatable.dart';

sealed class AddVehicleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddVehicleStarted extends AddVehicleEvent {}

/// Step 1 → 2
class Step1Submitted extends AddVehicleEvent {
  final String marca;
  final String modello;
  final int year;
  final String carburante;
  final String targa;

  Step1Submitted({
    required this.marca,
    required this.modello,
    required this.year,
    required this.carburante,
    required this.targa,
  });

  @override
  List<Object?> get props => [marca, modello, year, carburante, targa];
}

/// Step 2 → 3
class Step2Submitted extends AddVehicleEvent {
  final int? kmUltimoTagliando;
  final int? kmUltimaDistribuzione;
  final int? intervalloTagliando;
  final int? intervalloUltimaDistribuzione;

  Step2Submitted({
    this.kmUltimoTagliando,
    this.kmUltimaDistribuzione,
    this.intervalloTagliando,
    this.intervalloUltimaDistribuzione,
  });

  @override
  List<Object?> get props => [
    kmUltimoTagliando,
    kmUltimaDistribuzione,
    intervalloTagliando,
    intervalloUltimaDistribuzione,
  ];
}

/// Step 3 → 4
class Step3Submitted extends AddVehicleEvent {
  final int? potenzaCv;
  final int? cilindrata;
  final int? kmAttuali;

  Step3Submitted({this.potenzaCv, this.cilindrata, this.kmAttuali});

  @override
  List<Object?> get props => [potenzaCv, cilindrata, kmAttuali];
}

/// Step 4 → 5
class Step4Submitted extends AddVehicleEvent {
  final DateTime? prossimarevisione;
  final int? kmUltimoCambioGomme;
  final int? intervalloCambioGomme;
  final int? kmUltimaInversioneGomme;
  final int? intervalloInversioneGomme;

  Step4Submitted({
    this.prossimarevisione,
    this.kmUltimoCambioGomme,
    this.intervalloCambioGomme,
    this.kmUltimaInversioneGomme,
    this.intervalloInversioneGomme,
  });

  @override
  List<Object?> get props => [
    prossimarevisione,
    kmUltimoCambioGomme,
    intervalloCambioGomme,
    kmUltimaInversioneGomme,
    intervalloInversioneGomme,
  ];
}

/// Step 5 — salva wizard completo. L'ownerId viene letto dalla sessione
/// Supabase nel datasource remoto (layer data), non passa dalla presentation.
class SaveWizard extends AddVehicleEvent {
  final File? fotoFile;
  final String? codiceMeccanico;

  SaveWizard({this.fotoFile, this.codiceMeccanico});

  @override
  List<Object?> get props => [fotoFile, codiceMeccanico];
}

/// Indietro (currentStep - 1)
class StepBackPressed extends AddVehicleEvent {}

/// Reset completo (es. dopo successo o cancellazione)
class AddVehicleReset extends AddVehicleEvent {}
