import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/vehicle_repository.dart';

class ClearVehicleDraft {
  final VehicleRepository repository;
  const ClearVehicleDraft(this.repository);
  Future<Either<Failure, void>> call() => repository.clearDraft();
}
