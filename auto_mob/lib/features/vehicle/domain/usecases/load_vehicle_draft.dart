import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle_draft.dart';
import '../repositories/vehicle_repository.dart';

class LoadVehicleDraft {
  final VehicleRepository repository;
  const LoadVehicleDraft(this.repository);
  Future<Either<Failure, VehicleDraft?>> call() => repository.loadDraft();
}
