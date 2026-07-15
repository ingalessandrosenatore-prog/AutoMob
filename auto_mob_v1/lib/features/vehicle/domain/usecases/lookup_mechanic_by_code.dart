import 'package:fpdart/fpdart.dart';

import '../entities/mechanic_summary.dart';
import '../failures/vehicle_lookup_failure.dart';
import '../repositories/vehicle_lookup_repository.dart';

class LookupMechanicByCode {
  final VehicleLookupRepository repository;
  const LookupMechanicByCode(this.repository);

  Future<Either<VehicleLookupFailure, MechanicSummary?>> call(String code) =>
      repository.lookupMechanicByCode(code);
}
