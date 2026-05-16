
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entiti/MaintenanceEntity.dart';

abstract class WorklogRepo {

 //TODO: da modificare perche  maintance sono obsoleti vanno usati i worklogItem
  Future<Either<Failure, void>> insertWorklog({
    required MaintenanceRecord record,
    required MaintenanceItem item,
    required List<int> partIds,
  });
}