import 'package:fpdart/fpdart.dart';
import 'work_log_entry.dart';
import 'work_log_draft.dart';
import 'work_log_parts_data.dart';
import 'work_log_report.dart';
import 'work_log_vehicle.dart';

abstract interface class WorkLogRepository {
  Future<Either<String, List<WorkLogVehicle>>> getVehicles();
  Future<Either<String, WorkLogPartsData?>> getPartsData(String vehicleId);
  Future<Either<String, List<WorkLogReport>>> getOpenReports(String vehicleId);
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  });
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft);
}
