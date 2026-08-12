import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/vehicle_repository.dart';

class DisconnectMechanic {
  final VehicleRepository repository;

  const DisconnectMechanic(this.repository);

  Future<Either<Failure, void>> call({
    required String vehicleId,
    required String mechanicId,
  }) {
    if (vehicleId.isEmpty || mechanicId.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Officina o veicolo non valido.')),
      );
    }
    return repository.disconnectMechanic(
      vehicleId: vehicleId,
      mechanicId: mechanicId,
    );
  }
}
