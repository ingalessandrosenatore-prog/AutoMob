import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions/exceptions.dart';

import '../../domain/entities/vehicle_draft.dart';
import '../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  /// Salva il veicolo (anagrafica) + lavori iniziali in modo ATOMICO,
  /// tramite l'RPC `crea_veicolo_con_storico` (una sola transazione: o si
  /// salva tutto o niente). L'ownerId NON viene inviato: lo imposta l'RPC
  /// da auth.uid() (l'utente loggato).
  Future<void> saveVehicle(VehicleDraft draft);

  /// Lista veicoli accessibili dall'utente corrente (RLS filtra per owner_id).
  Future<List<VehicleModel>> getVehicles();

  /// Aggiorna i km del veicolo (modale "Aggiorna KM", senza lavoro) via RPC
  /// `aggiorna_km_veicolo`. I km salgono solo (mai indietro). Ritorna i km
  /// effettivi salvati sul DB.
  Future<int> updateKm({required String vehicleId, required int newKm});
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final SupabaseClient supabaseClient;
  // ignore: non_constant_identifier_names -- debito tecnico, vedi docs/TECH_DEBT.md
  String? get owner_id => supabaseClient.auth.currentUser?.id;

  VehicleRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> saveVehicle(VehicleDraft draft) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      // Una sola chiamata: l'RPC inserisce veicolo + record + item in
      // transazione. Se qualcosa fallisce, il DB fa rollback di tutto.
      await supabaseClient.rpc(
        'crea_veicolo_con_storico',
        params: {'p_payload': toSupabasePayload(draft)},
      );
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const VehicleDataSourceException(
        'Errore durante il salvataggio del veicolo',
      );
    }
  }

  @override
  Future<List<VehicleModel>> getVehicles() async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      // Leggo dalla VISTA "vista_veicoli_dashboard": ogni riga e' gia' un
      // veicolo completo di "ultimo intervento per tipo" (last_tagliando_km,
      // last_distribuzione_km, ...), calcolato lato DB partendo dai lavori.
      // UNA sola query, nessuna aggregazione in Dart.
      // Il filtro .eq('owner_id', ...) e' ridondante con la RLS (che gia'
      // mostra solo i miei veicoli), ma lo teniamo come secondo livello.
      final rows = await supabaseClient
          .from('vista_veicoli_dashboard')
          .select()
          .eq('owner_id', owner_id!);

      return (rows as List)
          .map(
            (r) => VehicleModel.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const VehicleDataSourceException(
        'Errore durante il caricamento dei veicoli',
      );
    }
  }

  @override
  Future<int> updateKm({required String vehicleId, required int newKm}) async {
    if (owner_id == null) {
      throw const ServerException('Utente non autenticato');
    }

    try {
      // L'RPC fa GREATEST + controllo proprietario; il trigger DB registra
      // l'aggiornamento nello storico km. Ritorna i km effettivi salvati.
      final result = await supabaseClient.rpc(
        'aggiorna_km_veicolo',
        params: {'p_vehicle_id': vehicleId, 'p_nuovo_km': newKm},
      );
      return (result as num).toInt();
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const VehicleDataSourceException(
        'Errore durante l\'aggiornamento dei km',
      );
    }
  }

  /// Trasforma il draft nel payload JSON che si aspetta l'RPC
  /// `crea_veicolo_con_storico`: { "veicolo": {...}, "lavori": [...] }.
  /// Niente owner_id qui: lo imposta l'RPC da auth.uid().
  Map<String, dynamic> toSupabasePayload(VehicleDraft draft) {
    // 1) Anagrafica veicolo. Tutti gli intervalli ora arrivano ESPLICITI dal
    //    wizard (ultimo km + intervallo per ogni manutenzione).
    final veicolo = <String, dynamic>{
      'plate': draft.targa?.toLowerCase(),
      'brand': draft.marca?.toLowerCase(),
      'model': draft.modello?.toLowerCase(),
      'year': draft.anno,
      'fuel': draft.carburante?.toLowerCase(),
      'km_current': draft.kmAttuali ?? 0,
      'power_cv': draft.potenzaCv,
      'displacement_cc': draft.cilindrata,
      'tagliando_interval_km': draft.intervalloUltimoTagliando,
      'distribution_intervall_km': draft.intervalloUltimaDistribuzione,
      'tire_change_interval_km': draft.intervalloCambioGomme,
      'tire_rotation_interval_km': draft.intervalloInversioneGomme,
      'scadenza_revision_date': draft.prossimarevisione
          ?.toIso8601String()
          .split('T')[0],
    };

    // 2) Lavori iniziali: un item per ogni manutenzione di cui conosciamo il km.
    final lavori = <Map<String, dynamic>>[
      if (draft.kmUltimoTagliando != null)
        {'type': 'tagliando', 'service_km': draft.kmUltimoTagliando},
      if (draft.kmUltimaDistribuzione != null)
        {'type': 'distribuzione', 'service_km': draft.kmUltimaDistribuzione},
      if (draft.kmUltimoCambioGomme != null)
        {'type': 'pneumatici_cambio', 'service_km': draft.kmUltimoCambioGomme},
      if (draft.kmUltimaInversioneGomme != null)
        {
          'type': 'pneumatici_inversione',
          'service_km': draft.kmUltimaInversioneGomme,
        },
    ];

    return {'veicolo': veicolo, 'lavori': lavori};
  }
}
