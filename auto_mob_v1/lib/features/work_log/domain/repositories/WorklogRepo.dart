
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entiti/MaintenanceEntity.dart';

abstract class WorklogRepo {


  Future<Either<Failure, void>> insertWorklog({
    required MaintenanceRecord record,
    required MaintenanceItem item,
    required List<int> partIds,
  });
}