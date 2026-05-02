import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../../../../core/error/Exception/Exceptions.dart';

import '../../domain/entities/vehicle_draft.dart';
import '../models/VehicleModel.dart';


abstract class VehicleRemoteDataSource {
  /// Salva il veicolo (anagrafica) + storici manutenzione + (opzionale) assegnazione meccanico.
  /// L'ownerId viene letto dalla sessione Supabase corrente.
  /// Atomicita' "manuale": se uno storico fallisce, il veicolo appena creato viene eliminato (rollback).
  /// Se il `codiceMeccanico` non e' valido o non attivo: nessun errore, solo log; veicolo salvato senza meccanico.
  Future<void> saveVehicle(VehicleDraft draft);

  /// Lista veicoli accessibili dall'utente corrente (RLS filtra per owner_id).
  Future<List<VehicleModel>> getVehicles();
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final SupabaseClient supabaseClient;
    String? get owner_id => supabaseClient.auth.currentUser?.id;

  VehicleRemoteDataSourceImpl({required this.supabaseClient});

//salva i veicoli su db in fase di registrazione con i rispettivi lavori esegfuiti usa toSupabasePlaylod
  @override
  Future<void> saveVehicle (VehicleDraft draft) async {


    if (owner_id == null) {
      throw ServerException('Utente non autenticato');
    }





      // 1. Prendi i dati dal tuo form model
      final payload = toSupabasePayload(draft);

      try {
        // 2. Chiami la funzione SQL passandogli il pacchetto
        await Supabase.instance.client.rpc(
          'salva_veicolo_iniziale',
          params: payload,
        );

        print('Veicolo e storico salvati con un colpo solo!');

      } catch (e) {
        print('Errore: $e');
      }


  }



  @override
  Future<List<VehicleModel>> getVehicles() async {

    try {
      final rows = await supabaseClient
          .from('vehicles')
          .select()
          .eq('owner_id',  owner_id!);

      const typeToField = {
        'tagliando': 'last_tagliando_km',
        'distribuzione': 'last_distribuzione_km',
        'pneumatici_cambio': 'last_tire_change_km',
        'pneumatici_inversione': 'last_tire_rotation_km',
      };

      // DEBUG: vediamo tutto cio' che l'utente puo' leggere
      print("[getVehicles] currentUser=${supabaseClient.auth.currentUser?.id}");
      final allItemsDbg = await supabaseClient.from('maintenance_items').select();
      print("[getVehicles] ALL items accessibili dal client: $allItemsDbg");
      final allRecsDbg = await supabaseClient.from('maintenance_records').select();
      print("[getVehicles] ALL records accessibili dal client: $allRecsDbg");

      // Carico tutti i record (id -> vehicle_id) e tutti gli items, poi aggrego in memoria.
      // Semplice e robusto: niente filtri embedded ne' inFilter.
      final allRecords = await supabaseClient
          .from('maintenance_records')
          .select('id, vehicle_id');
      final recordToVehicle = <String, String>{
        for (final r in (allRecords as List))
          (r as Map)['id'] as String: r['vehicle_id'] as String,
      };

      final allItems = await supabaseClient
          .from('maintenance_items')
          .select('service_km, service_date, type, record_id')
          .order('service_date', ascending: false);

      // vehicleId -> { type -> service_km } (primo trovato = piu' recente per via dell'order)
      final latestByVehicleType = <String, Map<String, int>>{};
      for (final item in (allItems as List)) {
        final m = item as Map;
        final recordId = m['record_id'] as String;
        final vId = recordToVehicle[recordId];
        if (vId == null) continue;
        final t = m['type'] as String;
        final byType = latestByVehicleType.putIfAbsent(vId, () => {});
        if (!byType.containsKey(t)) {
          byType[t] = (m['service_km'] as num).toInt();
        }
      }
      print("[getVehicles] latestByVehicleType=$latestByVehicleType");

      final result = <VehicleModel>[];
      for (final row in (rows as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final vehicleId = map['id'] as String;
        final byType = latestByVehicleType[vehicleId] ?? const {};
        for (final entry in typeToField.entries) {
          map[entry.value] = byType[entry.key];
        }
        print("[getVehicles] vehicleId=$vehicleId -> ${typeToField.values.map((f) => '$f=${map[f]}').join(', ')}");
        result.add(VehicleModel.fromJson(map));
      }

      print("query finita, vehicles=${result.length}");
      return result;

    } on PostgrestException catch (e) {
      print("query recupero veicoli fallita: ${e.message} | code=${e.code} | details=${e.details} | hint=${e.hint}");
      throw VehicleDataSourceException(e.message, code: e.code);

    } on SocketException {
      throw const NetworkException();
    } catch (e, st) {
      print("query recupero veicoli falllata2: $e\n$st");
      throw const VehicleDataSourceException('Errore durante il caricamento dei veicoli');
    }
  }


 // crea i dati da draft leggibili per il db e la funzione di salvataggio
  Map<String, dynamic> toSupabasePayload(VehicleDraft draft) {
    // 1. Prepariamo i dati secchi del veicolo
    final vehicleData = {
      'owner_id': owner_id,
      'plate': draft.targa?.toLowerCase(),
      'brand': draft.marca?.toLowerCase(),
      'model': draft.modello?.toLowerCase(),
      'year': draft.anno,
      'fuel': draft.carburante?.toLowerCase(),
      'km_current': draft.kmAttuali ?? 0,
    };

    // 2. Prepariamo la lista dei lavori (items)
    List<Map<String, dynamic>> itemsData = [];

    // Se c'è un tagliando, creiamo il suo "item"
    if (draft.dataUltimoTagliando != null && draft.kmUltimoTagliando != null) {
      itemsData.add({
        'type': 'tagliando',
        'service_date': draft.dataUltimoTagliando!.toIso8601String().split('T')[0], // Es: "2024-05-20"
        'service_km': draft.kmUltimoTagliando,
        // Se hai anche i dati del prossimo tagliando, aggiungili qui:
        // 'next_service_km': ...
      });
    }

    // Se c'è una distribuzione, creiamo un altro "item"
    if (draft.dataUltimaDistribuzione != null && draft.kmUltimaDistribuzione != null) {
      itemsData.add({
        'type': 'distribuzione',
        'service_date': draft.dataUltimaDistribuzione!.toIso8601String().split('T')[0],
        'service_km': draft.kmUltimaDistribuzione,
      });
    }

    // Idem per il cambio gomme...
    if (draft.kmUltimoCambioGomme != null) {
      itemsData.add({
        'type': 'pneumatici_cambio',
        // Se non hai la data esatta del cambio gomme, usiamo quella di oggi come fallback
        'service_date': DateTime.now().toIso8601String().split('T')[0],
        'service_km': draft.kmUltimoCambioGomme,
      });
    }

    if (draft.kmUltimaInversioneGomme != null) {
      itemsData.add({
        'type': 'pneumatici_inversione',
        // Se non hai la data esatta del cambio gomme, usiamo quella di oggi come fallback
        'service_date': DateTime.now().toIso8601String().split('T')[0],
        'service_km': draft.kmUltimaInversioneGomme,
      });
    }

    // 3. Impacchettiamo tutto per inviarlo alla funzione
    return {
      'v_data': vehicleData,
      'items_data': itemsData,
    };
  }

}
