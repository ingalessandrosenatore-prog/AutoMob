import 'package:fpdart/fpdart.dart';

import '../entities/vehicle_lookup_result.dart';
import '../failures/vehicle_lookup_failure.dart';
import '../repositories/vehicle_lookup_repository.dart';

class LookupVehicleByPlate {
  final VehicleLookupRepository repository;

  LookupVehicleByPlate(this.repository);

  Future<Either<VehicleLookupFailure, VehicleLookupResult>> call(String targa) {
    return repository.lookupByPlate(targa);
  }
}
