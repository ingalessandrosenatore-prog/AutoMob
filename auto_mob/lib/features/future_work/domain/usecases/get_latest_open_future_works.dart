import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/future_work_summary.dart';
import '../repositories/future_work_repository.dart';

class GetLatestOpenFutureWorks {
  const GetLatestOpenFutureWorks(this.repository);

  final FutureWorkRepository repository;

  Future<Either<Failure, List<FutureWorkSummary>>> call() =>
      repository.getLatestOpen();
}
