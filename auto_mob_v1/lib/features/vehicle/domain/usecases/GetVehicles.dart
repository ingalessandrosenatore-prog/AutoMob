import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entities/vehicle.dart';
import '../repositories/VehicleRepository.dart';

class GetVehicles {
  final VehicleRepository repository;

  GetVehicles(this.repository);

  Future<Either<Failure, List<Vehicle>>> call() {
    return repository.getVehicles();
  }
}
