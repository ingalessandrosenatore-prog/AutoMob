import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle_lookup_result.dart';
import '../repositories/vehicle_lookup_repository.dart';

class LookupVehicleByPlate {
  final VehicleLookupRepository repository;

  LookupVehicleByPlate(this.repository);

  Future<Either<Failure, VehicleLookupResult>> call(String targa) {
    return repository.lookupByPlate(targa);
  }
}
