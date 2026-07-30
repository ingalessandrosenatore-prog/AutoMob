import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions/exceptions.dart';
import '../../domain/entities/selected_part.dart';
import '../models/vehicle_option_model.dart';
import '../models/work_log_row_model.dart';

abstract class WorklogRemoteDataSource {
  /// Salva una sessione di manutenzione completa (record + item + parts + update interval).
  /// Atomica: chiamata RPC `crea_sessione_manutenzione` che gestisce la transazione su Postgres.
  Future<void> createWorkLog({
    required String vehicleId,
    required String type,
    String? customName,
    required int serviceKm,
    required DateTime serviceDate,
    String? notes,
    required int? intervallKm,
    required List<SelectedPart> items,
  });

  /// Veicoli dell'utente (colonne minime) per il dropdown dello storico.
  Future<List<VehicleOptionModel>> getVehicleOptions();

  /// Una pagina di lavori del veicolo, ordinati dal piu' recente.
  /// [from]/[to] sono indici inclusi (es. 0..19 = primi 20).
  Future<List<WorkLogRowModel>> getWorks({
    required String vehicleId,
    required int from,
    required int to,
  });
}

class WorklogRemoteDataSourceImpl implements WorklogRemoteDataSource {
  final SupabaseClient supabaseClient;
  String? get ownerId => supabaseClient.auth.currentUser?.id;

  WorklogRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<void> createWorkLog({
    required String vehicleId,
    required String type,
    String? customName,
    required int serviceKm,
    required DateTime serviceDate,
    String? notes,
    required int? intervallKm,
    required List<SelectedPart> items,
  }) async {
    final payload = {
      'vehicle_id': vehicleId,
      'type': type,
      'custom_name': customName,
      'service_km': serviceKm,
      'service_date': serviceDate.toIso8601String().split('T')[0],
      'notes': notes,
      'interval_km': intervallKm,
      'parts': items
          .map(
            (it) => {
              'part_id': it.partId,
              'quantity': it.quantity,
              'unit_price': it.unitPrice,
              'notes': it.note,
            },
          )
          .toList(),
    };

    try {
      await supabaseClient.rpc(
        'crea_sessione_manutenzione',
        params: {'p_payload': payload},
      );
    } on PostgrestException catch (e) {
      throw WorkLogDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const WorkLogDataSourceException(
        'Errore durante il salvataggio del WorkLog',
      );
    }
  }

  @override
  Future<List<VehicleOptionModel>> getVehicleOptions() async {
    if (ownerId == null) {
      throw const WorkLogDataSourceException('Utente non autenticato');
    }
    try {
      final rows = await supabaseClient
          .from('vehicles')
          .select('id, plate, brand, model, km_current')
          .eq('owner_id', ownerId!)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (r) => VehicleOptionModel.fromJson(
              Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw WorkLogDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const WorkLogDataSourceException(
        'Errore durante il caricamento dei veicoli',
      );
    }
  }

  @override
  Future<List<WorkLogRowModel>> getWorks({
    required String vehicleId,
    required int from,
    required int to,
  }) async {
    try {
      // I lavori stanno in `maintenance_items`; il vehicle_id e il mechanic_id
      // stanno nel record padre, agganciato con !inner per poterci filtrare.
      // .range(from, to) e' la "fetta" della paginazione (estremi inclusi).
      final rows = await supabaseClient
          .from('maintenance_items')
          .select(
            'id, type, custom_name, service_km, service_date, notes, '
            'maintenance_records!inner('
            'vehicle_id, mechanic_id, mechanics(business_name)), '
            'maintenance_item_parts('
            'part_id, quantity, unit_price, notes, parts(name))',
          )
          .eq('maintenance_records.vehicle_id', vehicleId)
          .order('service_date', ascending: false)
          .order('created_at', ascending: false)
          .range(from, to);

      return (rows as List)
          .map(
            (r) =>
                WorkLogRowModel.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw WorkLogDataSourceException(e.message, code: e.code);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw const WorkLogDataSourceException(
        'Errore durante il caricamento dei lavori',
      );
    }
  }
}
