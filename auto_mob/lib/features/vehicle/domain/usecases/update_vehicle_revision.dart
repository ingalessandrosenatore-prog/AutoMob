import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/vehicle_repository.dart';

class UpdateVehicleRevision {
  final VehicleRepository repository;

  UpdateVehicleRevision(this.repository);

  Future<Either<Failure, DateTime>> call({
    required String vehicleId,
    required DateTime nextRevisionDate,
  }) {
    return repository.updateRevisionDate(
      vehicleId: vehicleId,
      nextRevisionDate: nextRevisionDate,
    );
  }
}
