import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../entities/vehicle_draft.dart';
import '../repositories/VehicleRepository.dart';

class SaveDraftStep {
  final VehicleRepository repository;

  SaveDraftStep(this.repository);

  Future<Either<Failure, void>> call(VehicleDraft draft) {
    return repository.saveDraftStep(draft);
  }
}
