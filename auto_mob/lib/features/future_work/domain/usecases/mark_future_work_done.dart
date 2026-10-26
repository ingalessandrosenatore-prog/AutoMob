import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../repositories/future_work_repository.dart';

class MarkFutureWorkDone {
  const MarkFutureWorkDone(this.repository);
  final FutureWorkRepository repository;
  Future<Either<Failure, void>> call(String recordId) => recordId.trim().isEmpty
      ? Future.value(const Left(ValidationFailure('Segnalazione non valida.')))
      : repository.markDone(recordId);
}
