import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/mechanic_summary.dart';
import '../repositories/vehicle_repository.dart';

class ConnectMechanic {
  final VehicleRepository repository;

  const ConnectMechanic(this.repository);

  Future<Either<Failure, MechanicSummary>> call({
    required String vehicleId,
    required String mechanicCode,
  }) {
    final normalizedCode = mechanicCode.trim();
    if (normalizedCode.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Inserisci il codice del meccanico.')),
      );
    }
    return repository.connectMechanic(
      vehicleId: vehicleId,
      mechanicCode: normalizedCode,
    );
  }
}
