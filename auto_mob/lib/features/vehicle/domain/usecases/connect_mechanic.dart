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
    if (!RegExp(r'^[0-9]{6}$').hasMatch(normalizedCode)) {
      return Future.value(
        const Left(
          ValidationFailure('Il codice del meccanico deve contenere 6 cifre.'),
        ),
      );
    }
    return repository.connectMechanic(
      vehicleId: vehicleId,
      mechanicCode: normalizedCode,
    );
  }
}
