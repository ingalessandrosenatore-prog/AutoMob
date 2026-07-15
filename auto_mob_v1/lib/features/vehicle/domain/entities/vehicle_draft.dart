import 'dart:io';

import 'package:equatable/equatable.dart';

class VehicleDraft extends Equatable {
  static const _keep = Object();
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
  final String? meccanicoId;
  final String? meccanicoNome;
  final String? meccanicoIndirizzo;

  // Metadati del lookup. Servono a impedire una seconda richiesta a pagamento
  // e a collegare, al salvataggio, lo snapshot ricevuto da InfoTarga.
  final String? lookupId;
  final bool lookupAttemptConsumed;
  final bool datiInModifica;

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
    this.meccanicoId,
    this.meccanicoNome,
    this.meccanicoIndirizzo,
    this.lookupId,
    this.lookupAttemptConsumed = false,
    this.datiInModifica = false,
  });

  VehicleDraft copyWith({
    Object? targa = _keep,
    Object? marca = _keep,
    Object? modello = _keep,
    Object? anno = _keep,
    Object? carburante = _keep,
    Object? intervalloUltimoTagliando = _keep,
    Object? kmUltimoTagliando = _keep,
    Object? intervalloUltimaDistribuzione = _keep,
    Object? kmUltimaDistribuzione = _keep,
    Object? potenzaCv = _keep,
    Object? cilindrata = _keep,
    Object? kmAttuali = _keep,
    Object? prossimarevisione = _keep,
    Object? kmUltimoCambioGomme = _keep,
    Object? intervalloCambioGomme = _keep,
    Object? kmUltimaInversioneGomme = _keep,
    Object? intervalloInversioneGomme = _keep,
    Object? fotoFile = _keep,
    Object? codiceMeccanico = _keep,
    Object? meccanicoId = _keep,
    Object? meccanicoNome = _keep,
    Object? meccanicoIndirizzo = _keep,
    Object? lookupId = _keep,
    bool? lookupAttemptConsumed,
    bool? datiInModifica,
  }) {
    return VehicleDraft(
      targa: identical(targa, _keep) ? this.targa : targa as String?,
      marca: identical(marca, _keep) ? this.marca : marca as String?,
      modello: identical(modello, _keep) ? this.modello : modello as String?,
      anno: identical(anno, _keep) ? this.anno : anno as int?,
      carburante: identical(carburante, _keep)
          ? this.carburante
          : carburante as String?,
      intervalloUltimoTagliando: identical(intervalloUltimoTagliando, _keep)
          ? this.intervalloUltimoTagliando
          : intervalloUltimoTagliando as int?,
      kmUltimoTagliando: identical(kmUltimoTagliando, _keep)
          ? this.kmUltimoTagliando
          : kmUltimoTagliando as int?,
      intervalloUltimaDistribuzione:
          identical(intervalloUltimaDistribuzione, _keep)
          ? this.intervalloUltimaDistribuzione
          : intervalloUltimaDistribuzione as int?,
      kmUltimaDistribuzione: identical(kmUltimaDistribuzione, _keep)
          ? this.kmUltimaDistribuzione
          : kmUltimaDistribuzione as int?,
      potenzaCv: identical(potenzaCv, _keep)
          ? this.potenzaCv
          : potenzaCv as int?,
      cilindrata: identical(cilindrata, _keep)
          ? this.cilindrata
          : cilindrata as int?,
      kmAttuali: identical(kmAttuali, _keep)
          ? this.kmAttuali
          : kmAttuali as int?,
      prossimarevisione: identical(prossimarevisione, _keep)
          ? this.prossimarevisione
          : prossimarevisione as DateTime?,
      kmUltimoCambioGomme: identical(kmUltimoCambioGomme, _keep)
          ? this.kmUltimoCambioGomme
          : kmUltimoCambioGomme as int?,
      intervalloCambioGomme: identical(intervalloCambioGomme, _keep)
          ? this.intervalloCambioGomme
          : intervalloCambioGomme as int?,
      kmUltimaInversioneGomme: identical(kmUltimaInversioneGomme, _keep)
          ? this.kmUltimaInversioneGomme
          : kmUltimaInversioneGomme as int?,
      intervalloInversioneGomme: identical(intervalloInversioneGomme, _keep)
          ? this.intervalloInversioneGomme
          : intervalloInversioneGomme as int?,
      fotoFile: identical(fotoFile, _keep) ? this.fotoFile : fotoFile as File?,
      codiceMeccanico: identical(codiceMeccanico, _keep)
          ? this.codiceMeccanico
          : codiceMeccanico as String?,
      meccanicoId: identical(meccanicoId, _keep)
          ? this.meccanicoId
          : meccanicoId as String?,
      meccanicoNome: identical(meccanicoNome, _keep)
          ? this.meccanicoNome
          : meccanicoNome as String?,
      meccanicoIndirizzo: identical(meccanicoIndirizzo, _keep)
          ? this.meccanicoIndirizzo
          : meccanicoIndirizzo as String?,
      lookupId: identical(lookupId, _keep)
          ? this.lookupId
          : lookupId as String?,
      lookupAttemptConsumed:
          lookupAttemptConsumed ?? this.lookupAttemptConsumed,
      datiInModifica: datiInModifica ?? this.datiInModifica,
    );
  }

  @override
  List<Object?> get props => [
    targa,
    marca,
    modello,
    anno,
    carburante,
    intervalloUltimoTagliando,
    kmUltimoTagliando,
    intervalloUltimaDistribuzione,
    kmUltimaDistribuzione,
    potenzaCv,
    cilindrata,
    kmAttuali,
    prossimarevisione,
    kmUltimoCambioGomme,
    intervalloCambioGomme,
    kmUltimaInversioneGomme,
    intervalloInversioneGomme,
    fotoFile,
    codiceMeccanico,
    meccanicoId,
    meccanicoNome,
    meccanicoIndirizzo,
    lookupId,
    lookupAttemptConsumed,
    datiInModifica,
  ];
}
