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
  final DateTime? dataUltimoTagliando;
  final int? kmUltimoTagliando;
  final DateTime? dataUltimaDistribuzione;
  final int? kmUltimaDistribuzione;

  Step2Submitted({
    this.dataUltimoTagliando,
    this.kmUltimoTagliando,
    this.dataUltimaDistribuzione,
    this.kmUltimaDistribuzione,
  });

  @override
  List<Object?> get props => [
        dataUltimoTagliando,
        kmUltimoTagliando,
        dataUltimaDistribuzione,
        kmUltimaDistribuzione,
      ];
}

/// Step 3 → 4
class Step3Submitted extends AddVehicleEvent {
  final int? potenzaCv;
  final int? cilindrata;
  final int? kmAttuali;

  Step3Submitted({
    this.potenzaCv,
    this.cilindrata,
    this.kmAttuali,
  });

  @override
  List<Object?> get props => [potenzaCv, cilindrata, kmAttuali];
}

/// Step 4 → 5
class Step4Submitted extends AddVehicleEvent {
  final DateTime? prossimarevisione;
  final int? kmUltimoCambioGomme;
  final int? kmProssimoCambioGomme;
  final int? kmUltimaInversioneGomme;
  final int? kmProssimaInversioneGomme;

  Step4Submitted({
    this.prossimarevisione,
    this.kmUltimoCambioGomme,
    this.kmProssimoCambioGomme,
    this.kmUltimaInversioneGomme,
    this.kmProssimaInversioneGomme,
  });

  @override
  List<Object?> get props => [
        prossimarevisione,
        kmUltimoCambioGomme,
        kmProssimoCambioGomme,
        kmUltimaInversioneGomme,
        kmProssimaInversioneGomme,
      ];
}

/// Step 5 — salva wizard completo. L'ownerId viene letto dalla sessione
/// Supabase nel datasource remoto (layer data), non passa dalla presentation.
class SaveWizard extends AddVehicleEvent {
  final String? fotoPath;
  final String? codiceMeccanico;

  SaveWizard({this.fotoPath, this.codiceMeccanico});

  @override
  List<Object?> get props => [fotoPath, codiceMeccanico];
}

/// Indietro (currentStep - 1)
class StepBackPressed extends AddVehicleEvent {}

/// Reset completo (es. dopo successo o cancellazione)
class AddVehicleReset extends AddVehicleEvent {}
