import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entiti/WorkLogRow.dart';
import '../repositories/WorklogRepo.dart';

/// Recupera una pagina di lavori di un veicolo ([from]/[to] indici inclusi).
class GetVehicleWorks {
  final WorklogRepo worklogRepo;

  GetVehicleWorks(this.worklogRepo);

  Future<Either<Failure, List<WorkLogRow>>> call({
    required String vehicleId,
    required int from,
    required int to,
  }) {
    return worklogRepo.getWorks(vehicleId: vehicleId, from: from, to: to);
  }
}
