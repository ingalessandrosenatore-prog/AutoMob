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

  VehicleRemoteDataSourceImpl({required this.supabaseClient});


  @override
  Future<void> saveVehicle (VehicleDraft draft) async {
    final ownerId = supabaseClient.auth.currentUser?.id;

    if (ownerId == null) {
      throw ServerException('Utente non autenticato');
    }

    // Creiamo una mappa dinamica per evitare di inviare campi "null" se non necessari,
    // e gestiamo i constraint di Supabase.
    final payload = {
      'owner_id': ownerId,
      'plate': draft.targa?.toLowerCase(),
      'brand': draft.marca?.toLowerCase(),
      'model': draft.modello?.toLowerCase(),
      'year': draft.anno,
      'fuel': draft.carburante?.toLowerCase(), // Fondamentale per il constraint fuel_valid!
      if (draft.potenzaCv != null) 'power_cv': draft.potenzaCv,
      if (draft.cilindrata != null) 'displacement_cc': draft.cilindrata,
      'km_current': draft.kmAttuali ?? 0, // Fallback a 0 se null per rispettare il NOT NULL
    };

    // Se i campi obbligatori mancano, esploderà qui. Meglio stampare l'errore per debug.
    await supabaseClient.from('vehicles').insert(payload);


  }

  /// Costruisce gli item da passare in p_items alla RPC `add_maintenance_session`.
  /// Saltiamo gli storici senza km valorizzato.


  @override
  Future<List<VehicleModel>> getVehicles() async {
    try {
      final rows = await supabaseClient
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);

      return (rows as List)
          .map((row) => VehicleModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw VehicleDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (_) {
      throw const VehicleDataSourceException('Errore durante il caricamento dei veicoli');
    }
  }

  String _today() => _isoDate(DateTime.now());

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
