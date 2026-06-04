import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entiti/WorkLogItemEntity.dart';
import '../repositories/WorklogRepo.dart';

class CreateWorkLog {
  final WorklogRepo worklogRepo;

  CreateWorkLog(this.worklogRepo);

  Future<Either<Failure, void>> call({
    required String vehicleId,
    required String type,
    String? customName,
    required int serviceKm,
    required DateTime serviceDate,
    String? notes,
    required int? intervallKm,
    required List<WorkLogItem> items,
  }) {
    return worklogRepo.createWorkLog(
      vehicleId: vehicleId,
      type: type,
      customName: customName,
      serviceKm: serviceKm,
      serviceDate: serviceDate,
      notes: notes,
      intervallKm: intervallKm,
      items: items,
    );
  }
}
