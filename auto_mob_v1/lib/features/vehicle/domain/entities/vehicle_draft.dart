import 'dart:io';

import 'package:equatable/equatable.dart';

class VehicleDraft extends Equatable {
  // Step 1 — Dati base (tutti required)
  final String? targa;
  final String? marca;
  final String? modello;
  final int? anno;
  final String? carburante;

  // Step 2 — Tagliando e distribuzione
  final int? intervalloUltimoTagliando;
  final int? kmUltimoTagliando; // required
  final int? intervalloUltimaDistribuzione;
  final int? kmUltimaDistribuzione; // required

  // Step 3 — Dati tecnici
  final int? potenzaCv;
  final int? cilindrata;
  final int? kmAttuali; // required

  // Step 4 — Revisione e gomme
  final DateTime? prossimarevisione; // required
  final int? kmUltimoCambioGomme;
  final int? kmProssimoCambioGomme;
  final int? kmUltimaInversioneGomme;
  final int? kmProssimaInversioneGomme;

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
    this.kmProssimoCambioGomme,
    this.kmUltimaInversioneGomme,
    this.kmProssimaInversioneGomme,
    this.fotoFile,
    this.codiceMeccanico,
  });

  VehicleDraft copyWith({
    String? targa,
    String? marca,
    String? modello,
    int? anno,
    String? carburante,
    DateTime? dataUltimoTagliando,
    int? kmUltimoTagliando,
    DateTime? dataUltimaDistribuzione,
    int? kmUltimaDistribuzione,
    int? potenzaCv,
    int? cilindrata,
    int? kmAttuali,
    DateTime? prossimarevisione,
    int? kmUltimoCambioGomme,
    int? kmProssimoCambioGomme,
    int? kmUltimaInversioneGomme,
    int? kmProssimaInversioneGomme,
    String? fotoPath,
    String? codiceMeccanico,
    int? intervalloUltimaDistribuzione,
    int? intervalloUltimoTagliando,
    File ? fotoFile,
  }) {
    return VehicleDraft(
      targa: targa ?? this.targa,
      marca: marca ?? this.marca,
      modello: modello ?? this.modello,
      anno: anno ?? this.anno,
      carburante: carburante ?? this.carburante,
      intervalloUltimoTagliando: intervalloUltimoTagliando ?? this.intervalloUltimoTagliando,
      kmUltimoTagliando: kmUltimoTagliando ?? this.kmUltimoTagliando,
      intervalloUltimaDistribuzione: intervalloUltimaDistribuzione ?? this.intervalloUltimaDistribuzione,
      kmUltimaDistribuzione: kmUltimaDistribuzione ?? this.kmUltimaDistribuzione,
      potenzaCv: potenzaCv ?? this.potenzaCv,
      cilindrata: cilindrata ?? this.cilindrata,
      kmAttuali: kmAttuali ?? this.kmAttuali,
      prossimarevisione: prossimarevisione ?? this.prossimarevisione,
      kmUltimoCambioGomme: kmUltimoCambioGomme ?? this.kmUltimoCambioGomme,
      kmProssimoCambioGomme: kmProssimoCambioGomme ?? this.kmProssimoCambioGomme,
      kmUltimaInversioneGomme: kmUltimaInversioneGomme ?? this.kmUltimaInversioneGomme,
      kmProssimaInversioneGomme: kmProssimaInversioneGomme ?? this.kmProssimaInversioneGomme,
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
        kmUltimoCambioGomme, kmProssimoCambioGomme,
        kmUltimaInversioneGomme, kmProssimaInversioneGomme,
        fotoFile, codiceMeccanico,
      ];
}
