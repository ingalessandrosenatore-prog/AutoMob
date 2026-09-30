import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/fuel_expense_draft.dart';
import '../repositories/vehicle_repository.dart';

class AddFuelExpense {
  const AddFuelExpense(this.repository);

  final VehicleRepository repository;

  Future<Either<Failure, String>> call({
    required String vehicleId,
    required FuelExpenseDraft expense,
  }) {
    return repository.addFuelExpense(vehicleId: vehicleId, expense: expense);
  }
}
