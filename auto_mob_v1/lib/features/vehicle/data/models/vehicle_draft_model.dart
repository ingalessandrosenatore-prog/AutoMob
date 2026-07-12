import 'dart:io';

import '../../domain/entities/vehicle_draft.dart';

class VehicleDraftModel extends VehicleDraft {
  const VehicleDraftModel({
    super.targa,
    super.marca,
    super.modello,
    super.anno,
    super.carburante,

    super.intervalloUltimoTagliando,
    super.kmUltimoTagliando,
    super.intervalloUltimaDistribuzione,
    super.kmUltimaDistribuzione,
    super.potenzaCv,
    super.cilindrata,
    super.kmAttuali,
    super.prossimarevisione,
    super.kmUltimoCambioGomme,
    super.intervalloCambioGomme,
    super.kmUltimaInversioneGomme,
    super.intervalloInversioneGomme,
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

      intervalloUltimoTagliando: draft.intervalloUltimoTagliando,
      kmUltimoTagliando: draft.kmUltimoTagliando,

      intervalloUltimaDistribuzione: draft.intervalloUltimaDistribuzione,
      kmUltimaDistribuzione: draft.kmUltimaDistribuzione,
      potenzaCv: draft.potenzaCv,
      cilindrata: draft.cilindrata,
      kmAttuali: draft.kmAttuali,
      prossimarevisione: draft.prossimarevisione,
      kmUltimoCambioGomme: draft.kmUltimoCambioGomme,
      intervalloCambioGomme: draft.intervalloCambioGomme,
      kmUltimaInversioneGomme: draft.kmUltimaInversioneGomme,
      intervalloInversioneGomme: draft.intervalloInversioneGomme,
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

      intervalloUltimoTagliando: json['intervallo_ultimo_tagliando'],
      kmUltimoTagliando: json['km_ultimo_tagliando'],

      intervalloUltimaDistribuzione: json['intervallo_ultima_distribuzione'],
      kmUltimaDistribuzione: json['km_ultima_distribuzione'],
      potenzaCv: json['potenza_cv'],
      cilindrata: json['cilindrata'],
      kmAttuali: json['km_attuali'],
      prossimarevisione: json['prossima_revisione'] != null
          ? DateTime.parse(json['prossima_revisione'])
          : null,
      kmUltimoCambioGomme: json['km_ultimo_cambio_gomme'],
      intervalloCambioGomme: json['intervallo_cambio_gomme'],
      kmUltimaInversioneGomme: json['km_ultima_inversione_gomme'],
      intervalloInversioneGomme: json['intervallo_inversione_gomme'],
      codiceMeccanico: json['codice_meccanico'],
      fotoFile: json['foto_path'] != null
          ? File(json['foto_path'] as String)
          : null,
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

      'intervallo_ultimo_tagliando': intervalloUltimoTagliando,
      'km_ultimo_tagliando': kmUltimoTagliando,
      'intervallo_ultima_distribuzione': intervalloUltimaDistribuzione,
      'km_ultima_distribuzione': kmUltimaDistribuzione,
      'potenza_cv': potenzaCv,
      'cilindrata': cilindrata,
      'km_attuali': kmAttuali,
      'prossima_revisione': prossimarevisione?.toIso8601String(),
      'km_ultimo_cambio_gomme': kmUltimoCambioGomme,
      'intervallo_cambio_gomme': intervalloCambioGomme,
      'km_ultima_inversione_gomme': kmUltimaInversioneGomme,
      'intervallo_inversione_gomme': intervalloInversioneGomme,
      'codice_meccanico': codiceMeccanico,
      'foto_path': fotoFile?.path,
    };
  }
}
