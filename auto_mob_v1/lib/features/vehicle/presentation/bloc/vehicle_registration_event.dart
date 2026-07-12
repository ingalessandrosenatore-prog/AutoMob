import 'dart:io';

import 'package:equatable/equatable.dart';

sealed class VehicleRegistrationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Reset completo del flusso (apertura pagina).
class RegistrationStarted extends VehicleRegistrationEvent {}

/// Step 0 → 1 — codice meccanico (opzionale).
class MechanicStepSubmitted extends VehicleRegistrationEvent {
  final String? codiceMeccanico;

  MechanicStepSubmitted({this.codiceMeccanico});

  @override
  List<Object?> get props => [codiceMeccanico];
}

/// Step 1 → 2 — targa inserita, avvia il lookup (mock).
class PlateSubmitted extends VehicleRegistrationEvent {
  final String targa;

  PlateSubmitted({required this.targa});

  @override
  List<Object?> get props => [targa];
}

/// Step 2 → 3 — conferma (o correzione manuale) dei dati veicolo.
class VerifyStepSubmitted extends VehicleRegistrationEvent {
  final String? marca;
  final String? modello;
  final int? anno;
  final String? carburante;
  final int? cilindrata;

  VerifyStepSubmitted({
    this.marca,
    this.modello,
    this.anno,
    this.carburante,
    this.cilindrata,
  });

  @override
  List<Object?> get props => [marca, modello, anno, carburante, cilindrata];
}

/// Step 3 → 4 — ultimi lavori svolti (tagliando/distribuzione/gomme/revisione).
class WorkLogStepSubmitted extends VehicleRegistrationEvent {
  final int? kmAttuali;
  final int? intervalloTagliando;
  final int? kmUltimoTagliando;
  final int? intervalloUltimaDistribuzione;
  final int? kmUltimaDistribuzione;
  final DateTime? prossimarevisione;
  final int? kmUltimoCambioGomme;
  final int? intervalloCambioGomme;
  final int? kmUltimaInversioneGomme;
  final int? intervalloInversioneGomme;

  WorkLogStepSubmitted({
    this.kmAttuali,
    this.intervalloTagliando,
    this.kmUltimoTagliando,
    this.intervalloUltimaDistribuzione,
    this.kmUltimaDistribuzione,
    this.prossimarevisione,
    this.kmUltimoCambioGomme,
    this.intervalloCambioGomme,
    this.kmUltimaInversioneGomme,
    this.intervalloInversioneGomme,
  });

  @override
  List<Object?> get props => [
    kmAttuali,
    intervalloTagliando,
    kmUltimoTagliando,
    intervalloUltimaDistribuzione,
    kmUltimaDistribuzione,
    prossimarevisione,
    kmUltimoCambioGomme,
    intervalloCambioGomme,
    kmUltimaInversioneGomme,
    intervalloInversioneGomme,
  ];
}

/// Step 4 — foto veicolo, ultimo step del flusso (solo in-memory per ora).
class PhotoStepSubmitted extends VehicleRegistrationEvent {
  final File? fotoFile;

  PhotoStepSubmitted({this.fotoFile});

  @override
  List<Object?> get props => [fotoFile];
}

/// Indietro (currentStep - 1, clamp a 0).
class RegistrationStepBackPressed extends VehicleRegistrationEvent {}
