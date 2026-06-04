import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/Exception/Exceptions.dart';
import '../../domain/entiti/WorkLogItemEntity.dart';

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
    required List<WorkLogItem> items,
  });
}

class WorklogRemoteDataSourceImpl implements WorklogRemoteDataSource {
  final SupabaseClient supabaseClient;

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
    required List<WorkLogItem> items,
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
          .map((it) => {
                'part_id': it.partId,
                'quantity': it.partQuantity,
                'unit_price': it.partPrice,
                'notes': it.partNote,
              })
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
      throw const WorkLogDataSourceException('Errore durante il salvataggio del WorkLog');
    }
  }
}
