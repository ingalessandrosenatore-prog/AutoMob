import 'package:fpdart/fpdart.dart';
import '../domain/work_log_entry.dart';
import '../domain/work_log_draft.dart';
import '../domain/work_log_repository.dart';
import '../domain/work_log_vehicle.dart';
import 'work_log_remote_data_source.dart';

class WorkLogRepositoryImpl implements WorkLogRepository {
  const WorkLogRepositoryImpl(this._remote);
  final WorkLogRemoteDataSource _remote;
  @override
  Future<Either<String, List<WorkLogVehicle>>> getVehicles() async {
    try {
      return right(await _remote.getVehicles());
    } catch (_) {
      return left('Impossibile caricare i veicoli.');
    }
  }

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async {
    try {
      return right(
        await _remote.getVehicleWorks(vehicleId, from: from, to: to),
      );
    } catch (_) {
      return left('Impossibile caricare lo storico dei lavori.');
    }
  }

  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) async {
    try {
      await _remote.createWorkLog(draft);
      return right(unit);
    } catch (_) {
      return left('Impossibile salvare il lavoro.');
    }
  }
}
