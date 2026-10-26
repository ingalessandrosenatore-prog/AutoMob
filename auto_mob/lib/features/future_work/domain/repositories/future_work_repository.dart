import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../entities/future_work_report.dart';
import '../entities/future_work_summary.dart';
import '../entities/warning_light_observation.dart';

abstract class FutureWorkRepository {
  Future<Either<Failure, void>> markDone(String recordId);

  Future<Either<Failure, List<FutureWorkSummary>>> getLatestOpen();

  Future<Either<Failure, FutureWorkReport>> createReport({
    required String vehicleId,
    required String description,
    String onboardMessage = '',
    List<WarningLightObservation> warningLights = const [],
    required DateTime reminderDate,
  });
}
