import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle_draft.dart';
import '../repositories/vehicle_repository.dart';

class SaveVehicle {
  final VehicleRepository repository;

  SaveVehicle(this.repository);

  Future<Either<Failure, void>> call(VehicleDraft draft) async  {
     return  repository.saveVehicle(draft);
  }
}
