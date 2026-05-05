import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entities/vehicle_draft.dart';
import '../repositories/VehicleRepository.dart';

class SaveVehicle {
  final VehicleRepository repository;

  SaveVehicle(this.repository);

  Future<Either<Failure, void>> call(VehicleDraft draft) async  {
     return  repository.saveVehicle(draft);
  }
}
