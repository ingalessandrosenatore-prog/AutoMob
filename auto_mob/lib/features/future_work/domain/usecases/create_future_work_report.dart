import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/future_work_report.dart';
import '../repositories/future_work_repository.dart';

class CreateFutureWorkReport {
  CreateFutureWorkReport(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final FutureWorkRepository repository;
  final DateTime Function() _now;

  Future<Either<Failure, FutureWorkReport>> call({
    required String vehicleId,
    required String description,
    required DateTime reminderDate,
  }) {
    final normalizedDescription = description.trim();
    if (vehicleId.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Veicolo non valido.')));
    }
    if (normalizedDescription.isEmpty || normalizedDescription.length > 1000) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Descrivi il problema usando massimo 1000 caratteri.',
          ),
        ),
      );
    }

    final today = _dateOnly(_now());
    final deadline = _dateOnly(reminderDate);
    if (deadline.isBefore(today)) {
      return Future.value(
        const Left(
          ValidationFailure('La data di richiamo non può essere nel passato.'),
        ),
      );
    }

    return repository.createReport(
      vehicleId: vehicleId,
      description: normalizedDescription,
      reminderDate: deadline,
    );
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
