import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entiti/WorkLogItemEntity.dart';

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
    required List<WorkLogItem> items,
  });
}
