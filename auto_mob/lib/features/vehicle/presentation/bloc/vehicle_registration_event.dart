import 'dart:io';
import 'package:equatable/equatable.dart';

sealed class VehicleRegistrationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class RegistrationStarted extends VehicleRegistrationEvent {}

class MechanicStepSubmitted extends VehicleRegistrationEvent {
  final String? codiceMeccanico;
  MechanicStepSubmitted({this.codiceMeccanico});
  @override
  List<Object?> get props => [codiceMeccanico];
}

class RegistrationWithoutMechanicPressed extends VehicleRegistrationEvent {}

class PlateSubmitted extends VehicleRegistrationEvent {
  final String targa;
  PlateSubmitted({required this.targa});
  @override
  List<Object?> get props => [targa];
}

/// Prosegue senza interrogare servizi esterni e apre la compilazione manuale.
class ManualPlateSubmitted extends VehicleRegistrationEvent {
  final String targa;
  ManualPlateSubmitted({required this.targa});
  @override
  List<Object?> get props => [targa];
}

class LookupClosedWithManualEntry extends VehicleRegistrationEvent {}

/// Il popup informativo e' stato letto: evita che venga mostrato di nuovo
/// quando l'utente passa allo step successivo.
class LookupDialogAcknowledged extends VehicleRegistrationEvent {}

class VerifyStepSubmitted extends VehicleRegistrationEvent {
  final String? targa;
  final String? marca;
  final String? modello;
  final int? anno;
  final String? carburante;
  final int? cilindrata;
  final int? potenzaCv;
  VerifyStepSubmitted({
    this.targa,
    this.marca,
    this.modello,
    this.anno,
    this.carburante,
    this.cilindrata,
    this.potenzaCv,
  });
  @override
  List<Object?> get props => [
    targa,
    marca,
    modello,
    anno,
    carburante,
    cilindrata,
    potenzaCv,
  ];
}

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

class PhotoStepSubmitted extends VehicleRegistrationEvent {
  final File? fotoFile;
  PhotoStepSubmitted({this.fotoFile});
  @override
  List<Object?> get props => [fotoFile];
}

class RegistrationStepBackPressed extends VehicleRegistrationEvent {}

class RegistrationDraftDiscarded extends VehicleRegistrationEvent {}

class RegistrationDraftSaveRequested extends VehicleRegistrationEvent {}
