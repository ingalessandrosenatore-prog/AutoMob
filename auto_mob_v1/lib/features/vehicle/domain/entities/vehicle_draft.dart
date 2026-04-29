import 'package:equatable/equatable.dart';

class VehicleDraft extends Equatable {
  // Step 1 — Dati base (tutti required)
  final String? targa;
  final String? marca;
  final String? modello;
  final int? anno;
  final String? carburante;

  // Step 2 — Tagliando e distribuzione
  final DateTime? dataUltimoTagliando;
  final int? kmUltimoTagliando; // required
  final DateTime? dataUltimaDistribuzione;
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
  final String? fotoPath; // path locale, non va sul DB
  final String? codiceMeccanico;

  const VehicleDraft({
    this.targa,
    this.marca,
    this.modello,
    this.anno,
    this.carburante,
    this.dataUltimoTagliando,
    this.kmUltimoTagliando,
    this.dataUltimaDistribuzione,
    this.kmUltimaDistribuzione,
    this.potenzaCv,
    this.cilindrata,
    this.kmAttuali,
    this.prossimarevisione,
    this.kmUltimoCambioGomme,
    this.kmProssimoCambioGomme,
    this.kmUltimaInversioneGomme,
    this.kmProssimaInversioneGomme,
    this.fotoPath,
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
  }) {
    return VehicleDraft(
      targa: targa ?? this.targa,
      marca: marca ?? this.marca,
      modello: modello ?? this.modello,
      anno: anno ?? this.anno,
      carburante: carburante ?? this.carburante,
      dataUltimoTagliando: dataUltimoTagliando ?? this.dataUltimoTagliando,
      kmUltimoTagliando: kmUltimoTagliando ?? this.kmUltimoTagliando,
      dataUltimaDistribuzione: dataUltimaDistribuzione ?? this.dataUltimaDistribuzione,
      kmUltimaDistribuzione: kmUltimaDistribuzione ?? this.kmUltimaDistribuzione,
      potenzaCv: potenzaCv ?? this.potenzaCv,
      cilindrata: cilindrata ?? this.cilindrata,
      kmAttuali: kmAttuali ?? this.kmAttuali,
      prossimarevisione: prossimarevisione ?? this.prossimarevisione,
      kmUltimoCambioGomme: kmUltimoCambioGomme ?? this.kmUltimoCambioGomme,
      kmProssimoCambioGomme: kmProssimoCambioGomme ?? this.kmProssimoCambioGomme,
      kmUltimaInversioneGomme: kmUltimaInversioneGomme ?? this.kmUltimaInversioneGomme,
      kmProssimaInversioneGomme: kmProssimaInversioneGomme ?? this.kmProssimaInversioneGomme,
      fotoPath: fotoPath ?? this.fotoPath,
      codiceMeccanico: codiceMeccanico ?? this.codiceMeccanico,
    );
  }

  @override
  List<Object?> get props => [
        targa, marca, modello, anno, carburante,
        dataUltimoTagliando, kmUltimoTagliando,
        dataUltimaDistribuzione, kmUltimaDistribuzione,
        potenzaCv, cilindrata, kmAttuali,
        prossimarevisione,
        kmUltimoCambioGomme, kmProssimoCambioGomme,
        kmUltimaInversioneGomme, kmProssimaInversioneGomme,
        fotoPath, codiceMeccanico,
      ];
}
