import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/future_work_report.dart';
import '../entities/future_work_summary.dart';

abstract class FutureWorkRepository {
  Future<Either<Failure, List<FutureWorkSummary>>> getLatestOpen();

  Future<Either<Failure, FutureWorkReport>> createReport({
    required String vehicleId,
    required String description,
    required DateTime reminderDate,
  });
}
