import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/vehicle_draft.dart';
import '../repositories/vehicle_repository.dart';

class SaveDraftStep {
  final VehicleRepository repository;

  SaveDraftStep(this.repository);

  Future<Either<Failure, void>> call(VehicleDraft draft) {
    return repository.saveDraftStep(draft);
  }
}
