import 'dart:io';

import 'package:equatable/equatable.dart';

class VehicleDraft extends Equatable {
  // Step 1 — Dati base
  final String? targa;
  final String? marca;
  final String? modello;
  final int? anno;
  final String? carburante;

  // Step 2 — Tagliando e distribuzione (ultimo km + intervallo, espliciti)
  final int? intervalloUltimoTagliando;
  final int? kmUltimoTagliando;
  final int? intervalloUltimaDistribuzione;
  final int? kmUltimaDistribuzione;

  // Step 3 — Dati tecnici
  final int? potenzaCv;
  final int? cilindrata;
  final int? kmAttuali;

  // Step 4 — Revisione e gomme (ultimo km + intervallo, espliciti)
  final DateTime? prossimarevisione;
  final int? kmUltimoCambioGomme;
  final int? intervalloCambioGomme;
  final int? kmUltimaInversioneGomme;
  final int? intervalloInversioneGomme;

  // Step 5 — Foto e meccanico
  final File? fotoFile; // path locale, non va sul DB
  final String? codiceMeccanico;

  const VehicleDraft({
    this.targa,
    this.marca,
    this.modello,
    this.anno,
    this.carburante,
    this.intervalloUltimoTagliando,
    this.kmUltimoTagliando,
    this.intervalloUltimaDistribuzione,
    this.kmUltimaDistribuzione,
    this.potenzaCv,
    this.cilindrata,
    this.kmAttuali,
    this.prossimarevisione,
    this.kmUltimoCambioGomme,
    this.intervalloCambioGomme,
    this.kmUltimaInversioneGomme,
    this.intervalloInversioneGomme,
    this.fotoFile,
    this.codiceMeccanico,
  });

  VehicleDraft copyWith({
    String? targa,
    String? marca,
    String? modello,
    int? anno,
    String? carburante,
    int? intervalloUltimoTagliando,
    int? kmUltimoTagliando,
    int? intervalloUltimaDistribuzione,
    int? kmUltimaDistribuzione,
    int? potenzaCv,
    int? cilindrata,
    int? kmAttuali,
    DateTime? prossimarevisione,
    int? kmUltimoCambioGomme,
    int? intervalloCambioGomme,
    int? kmUltimaInversioneGomme,
    int? intervalloInversioneGomme,
    File? fotoFile,
    String? codiceMeccanico,
  }) {
    return VehicleDraft(
      targa: targa ?? this.targa,
      marca: marca ?? this.marca,
      modello: modello ?? this.modello,
      anno: anno ?? this.anno,
      carburante: carburante ?? this.carburante,
      intervalloUltimoTagliando:
          intervalloUltimoTagliando ?? this.intervalloUltimoTagliando,
      kmUltimoTagliando: kmUltimoTagliando ?? this.kmUltimoTagliando,
      intervalloUltimaDistribuzione:
          intervalloUltimaDistribuzione ?? this.intervalloUltimaDistribuzione,
      kmUltimaDistribuzione: kmUltimaDistribuzione ?? this.kmUltimaDistribuzione,
      potenzaCv: potenzaCv ?? this.potenzaCv,
      cilindrata: cilindrata ?? this.cilindrata,
      kmAttuali: kmAttuali ?? this.kmAttuali,
      prossimarevisione: prossimarevisione ?? this.prossimarevisione,
      kmUltimoCambioGomme: kmUltimoCambioGomme ?? this.kmUltimoCambioGomme,
      intervalloCambioGomme:
          intervalloCambioGomme ?? this.intervalloCambioGomme,
      kmUltimaInversioneGomme:
          kmUltimaInversioneGomme ?? this.kmUltimaInversioneGomme,
      intervalloInversioneGomme:
          intervalloInversioneGomme ?? this.intervalloInversioneGomme,
      fotoFile: fotoFile ?? this.fotoFile,
      codiceMeccanico: codiceMeccanico ?? this.codiceMeccanico,
    );
  }

  @override
  List<Object?> get props => [
        targa, marca, modello, anno, carburante,
        intervalloUltimoTagliando, kmUltimoTagliando,
        intervalloUltimaDistribuzione, kmUltimaDistribuzione,
        potenzaCv, cilindrata, kmAttuali,
        prossimarevisione,
        kmUltimoCambioGomme, intervalloCambioGomme,
        kmUltimaInversioneGomme, intervalloInversioneGomme,
        fotoFile, codiceMeccanico,
      ];
}
