import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle_option.dart';
import '../repositories/worklog_repo.dart';

/// Recupera i veicoli dell'utente per il dropdown dello storico lavori.
class GetVehicleOptions {
  final WorklogRepo worklogRepo;

  GetVehicleOptions(this.worklogRepo);

  Future<Either<Failure, List<VehicleOption>>> call() {
    return worklogRepo.getVehicleOptions();
  }
}
