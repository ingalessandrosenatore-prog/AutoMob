import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../../domain/entities/future_work_report.dart';
import '../../domain/entities/future_work_summary.dart';
import '../../domain/repositories/future_work_repository.dart';
import '../datasources/future_work_remote_data_source.dart';

class FutureWorkRepositoryImpl implements FutureWorkRepository {
  const FutureWorkRepositoryImpl(this.remoteDataSource);

  final FutureWorkRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<FutureWorkSummary>>> getLatestOpen() async {
    try {
      return Right(await remoteDataSource.getLatestOpen());
    } on SocketException {
      return const Left(NetworkFailure());
    } on FutureWorkDataSourceException catch (error) {
      return Left(RemoteFailure(error.message, code: error.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, FutureWorkReport>> createReport({
    required String vehicleId,
    required String description,
    required DateTime reminderDate,
  }) async {
    try {
      final id = await remoteDataSource.createReport(
        vehicleId: vehicleId,
        description: description,
        reminderDate: reminderDate,
      );
      return Right(
        FutureWorkReport(
          id: id,
          vehicleId: vehicleId,
          description: description,
          reminderDate: reminderDate,
        ),
      );
    } on SocketException {
      return const Left(NetworkFailure());
    } on FutureWorkDataSourceException catch (error) {
      return switch (error.code) {
        '42501' => const Left(PermissionFailure()),
        '22023' => Left(ValidationFailure(error.message)),
        _ => Left(RemoteFailure(error.message, code: error.code)),
      };
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
