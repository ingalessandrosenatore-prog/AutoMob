import 'dart:io';

import '../../domain/entities/vehicle_draft.dart';
import '../../domain/entities/vehicle_maintenance_setting.dart';

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
    super.maintenanceSettings,
    super.brakeInspectionDate,
    super.fotoFile,
    super.codiceMeccanico,
    super.meccanicoId,
    super.meccanicoNome,
    super.meccanicoIndirizzo,
    super.lookupId,
    super.lookupAttemptConsumed,
    super.datiInModifica,
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
      maintenanceSettings: draft.maintenanceSettings,
      brakeInspectionDate: draft.brakeInspectionDate,
      fotoFile: draft.fotoFile,
      codiceMeccanico: draft.codiceMeccanico,
      meccanicoId: draft.meccanicoId,
      meccanicoNome: draft.meccanicoNome,
      meccanicoIndirizzo: draft.meccanicoIndirizzo,
      lookupId: draft.lookupId,
      lookupAttemptConsumed: draft.lookupAttemptConsumed,
      datiInModifica: draft.datiInModifica,
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
      maintenanceSettings: _maintenanceSettingsFromJson(
        json['maintenance_settings'],
      ),
      brakeInspectionDate: DateTime.tryParse(
        json['brake_inspection_date'] as String? ?? '',
      ),
      codiceMeccanico: json['codice_meccanico'],
      meccanicoId: json['meccanico_id'],
      meccanicoNome: json['meccanico_nome'],
      meccanicoIndirizzo: json['meccanico_indirizzo'],
      lookupId: json['lookup_id'],
      lookupAttemptConsumed: json['lookup_attempt_consumed'] == true,
      datiInModifica: json['dati_in_modifica'] == true,
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
      'maintenance_settings': [
        for (final setting in maintenanceSettings)
          {
            'field': setting.field.name,
            'interval_km': setting.intervalKm,
            'interval_years': setting.intervalYears,
            'last_km': setting.lastKm,
            'last_date': setting.lastDate?.toIso8601String(),
          },
      ],
      'brake_inspection_date': brakeInspectionDate?.toIso8601String(),
      'codice_meccanico': codiceMeccanico,
      'meccanico_id': meccanicoId,
      'meccanico_nome': meccanicoNome,
      'meccanico_indirizzo': meccanicoIndirizzo,
      'lookup_id': lookupId,
      'lookup_attempt_consumed': lookupAttemptConsumed,
      'dati_in_modifica': datiInModifica,
      'foto_path': fotoFile?.path,
    };
  }
}

List<VehicleMaintenanceSetting> _maintenanceSettingsFromJson(Object? raw) {
  if (raw is! List) return const [];
  final fields = {
    for (final field in VehicleMaintenanceField.values) field.name: field,
  };
  return List.unmodifiable([
    for (final row in raw.whereType<Map<String, dynamic>>())
      if (fields[row['field']] case final field?)
        VehicleMaintenanceSetting(
          field: field,
          intervalKm: row['interval_km'] as int?,
          intervalYears: row['interval_years'] as int?,
          lastKm: row['last_km'] as int?,
          lastDate: DateTime.tryParse(row['last_date'] as String? ?? ''),
        ),
  ]);
}
