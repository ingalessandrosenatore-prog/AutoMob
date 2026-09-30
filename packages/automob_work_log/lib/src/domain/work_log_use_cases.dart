import 'package:fpdart/fpdart.dart';
import 'work_log_entry.dart';
import 'work_log_draft.dart';
import 'work_log_repository.dart';
import 'work_log_vehicle.dart';

class GetWorkLogVehicles {
  const GetWorkLogVehicles(this._repository);
  final WorkLogRepository _repository;
  Future<Either<String, List<WorkLogVehicle>>> call() =>
      _repository.getVehicles();
}

class GetVehicleWorkHistory {
  const GetVehicleWorkHistory(this._repository);
  final WorkLogRepository _repository;
  Future<Either<String, List<WorkLogEntry>>> call(
    String vehicleId, {
    required int from,
    required int to,
  }) => _repository.getVehicleWorks(vehicleId, from: from, to: to);
}

class CreateWorkLog {
  const CreateWorkLog(this._repository);
  final WorkLogRepository _repository;
  Future<Either<String, Unit>> call(WorkLogDraft draft) =>
      _repository.createWorkLog(draft);
}
