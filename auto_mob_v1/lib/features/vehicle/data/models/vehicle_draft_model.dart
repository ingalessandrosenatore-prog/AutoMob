import 'dart:io';

import '../../domain/entities/vehicle_draft.dart';

class VehicleDraftModel extends VehicleDraft {
  const VehicleDraftModel({
    super.targa,
    super.marca,
    super.modello,
    super.anno,
    super.carburante,

    super.kmUltimoTagliando,
    super.kmUltimaDistribuzione,
    super.potenzaCv,
    super.cilindrata,
    super.kmAttuali,
    super.prossimarevisione,
    super.kmUltimoCambioGomme,
    super.kmProssimoCambioGomme,
    super.kmUltimaInversioneGomme,
    super.kmProssimaInversioneGomme,
    super.fotoFile,
    super.codiceMeccanico,
  });

  factory VehicleDraftModel.fromDraft(VehicleDraft draft) {
    return VehicleDraftModel(
      targa: draft.targa,
      marca: draft.marca,
      modello: draft.modello,
      anno: draft.anno,
      carburante: draft.carburante,

      kmUltimoTagliando: draft.kmUltimoTagliando,

      kmUltimaDistribuzione: draft.kmUltimaDistribuzione,
      potenzaCv: draft.potenzaCv,
      cilindrata: draft.cilindrata,
      kmAttuali: draft.kmAttuali,
      prossimarevisione: draft.prossimarevisione,
      kmUltimoCambioGomme: draft.kmUltimoCambioGomme,
      kmProssimoCambioGomme: draft.kmProssimoCambioGomme,
      kmUltimaInversioneGomme: draft.kmUltimaInversioneGomme,
      kmProssimaInversioneGomme: draft.kmProssimaInversioneGomme,
      fotoFile: draft.fotoFile,
      codiceMeccanico: draft.codiceMeccanico,
    );
  }

  factory VehicleDraftModel.fromJson(Map<String, dynamic> json) {
    return VehicleDraftModel(
      targa: json['targa'],
      marca: json['marca'],
      modello: json['modello'],
      anno: json['anno'],
      carburante: json['carburante'],

      kmUltimoTagliando: json['km_ultimo_tagliando'],

      kmUltimaDistribuzione: json['km_ultima_distribuzione'],
      potenzaCv: json['potenza_cv'],
      cilindrata: json['cilindrata'],
      kmAttuali: json['km_attuali'],
      prossimarevisione: json['prossima_revisione'] != null
          ? DateTime.parse(json['prossima_revisione'])
          : null,
      kmUltimoCambioGomme: json['km_ultimo_cambio_gomme'],
      kmProssimoCambioGomme: json['km_prossimo_cambio_gomme'],
      kmUltimaInversioneGomme: json['km_ultima_inversione_gomme'],
      kmProssimaInversioneGomme: json['km_prossima_inversione_gomme'],
      codiceMeccanico: json['codice_meccanico'],
      fotoFile: json['foto_path'] != null ? File(json['foto_path'] as String) : null,
    );
  }

  // Usato per SharedPreferences — include fotoPath
  Map<String, dynamic> toJson() {
    return {
      'targa': targa,
      'marca': marca,
      'modello': modello,
      'anno': anno,
      'carburante': carburante,

      'km_ultimo_tagliando': kmUltimoTagliando,
      'km_ultima_distribuzione': kmUltimaDistribuzione,
      'potenza_cv': potenzaCv,
      'cilindrata': cilindrata,
      'km_attuali': kmAttuali,
      'prossima_revisione': prossimarevisione?.toIso8601String(),
      'km_ultimo_cambio_gomme': kmUltimoCambioGomme,
      'km_prossimo_cambio_gomme': kmProssimoCambioGomme,
      'km_ultima_inversione_gomme': kmUltimaInversioneGomme,
      'km_prossima_inversione_gomme': kmProssimaInversioneGomme,
      'codice_meccanico': codiceMeccanico,
      'foto_path': fotoFile?.path,
    };
  }

}
