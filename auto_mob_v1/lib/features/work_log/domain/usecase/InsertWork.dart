import 'package:auto_mob_v1/features/work_log/domain/repositories/WorklogRepo.dart';
import 'package:flutter/cupertino.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../entiti/MaintenanceEntity.dart';

class InsertWork {
  final WorklogRepo worklogRepo;

  InsertWork({required this.worklogRepo});

  Future<Either<Failure, void>> call({
    required MaintenanceRecord record,
    required MaintenanceItem item,
    required List<int> parts,
  }) {
    return worklogRepo.insertWorklog(
      record: record,
      item: item,
      partIds: [],
    );
  }
}
