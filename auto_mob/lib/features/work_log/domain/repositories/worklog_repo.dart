import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/selected_part.dart';
import '../entities/vehicle_option.dart';
import '../entities/work_log_row.dart';

abstract class WorklogRepo {
  /// Salva una sessione di manutenzione completa (record + item + parts + update interval).
  /// Atomica via RPC Supabase.
  Future<Either<Failure, void>> createWorkLog({
    required String vehicleId,
    required String type,
    String? customName,
    required int serviceKm,
    required DateTime serviceDate,
    String? notes,
    required int? intervallKm,
    required List<SelectedPart> items,
  });

  /// Veicoli dell'utente per il dropdown dello storico.
  Future<Either<Failure, List<VehicleOption>>> getVehicleOptions();

  /// Una pagina di lavori del veicolo ([from]/[to] indici inclusi).
  Future<Either<Failure, List<WorkLogRow>>> getWorks({
    required String vehicleId,
    required int from,
    required int to,
  });
}
