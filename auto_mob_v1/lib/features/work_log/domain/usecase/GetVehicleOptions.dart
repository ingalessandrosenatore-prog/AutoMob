import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entiti/VehicleOption.dart';
import '../repositories/WorklogRepo.dart';

/// Recupera i veicoli dell'utente per il dropdown dello storico lavori.
class GetVehicleOptions {
  final WorklogRepo worklogRepo;

  GetVehicleOptions(this.worklogRepo);

  Future<Either<Failure, List<VehicleOption>>> call() {
    return worklogRepo.getVehicleOptions();
  }
}
