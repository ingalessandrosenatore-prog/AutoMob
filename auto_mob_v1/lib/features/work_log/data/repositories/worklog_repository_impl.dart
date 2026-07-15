import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../../../../core/error/exceptions/exceptions.dart';
import '../../domain/entities/selected_part.dart';
import '../../domain/entities/vehicle_option.dart';
import '../../domain/entities/work_log_row.dart';
import '../../domain/repositories/worklog_repo.dart';
import '../datasources/worklog_remote_data_source.dart';

class WorklogRepositoryImpl implements WorklogRepo {
  final WorklogRemoteDataSource remoteDataSource;

  WorklogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> createWorkLog({
    required String vehicleId,
    required String type,
    String? customName,
    required int serviceKm,
    required DateTime serviceDate,
    String? notes,
    required int? intervallKm,
    required List<SelectedPart> items,
  }) async {
    try {
      await remoteDataSource.createWorkLog(
        vehicleId: vehicleId,
        type: type,
        customName: customName,
        serviceKm: serviceKm,
        serviceDate: serviceDate,
        notes: notes,
        intervallKm: intervallKm,
        items: items,
      );
      return const Right(null);
    } on WorkLogDataSourceException catch (error) {
      return Left(CodedServerFailure(code: error.code));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<VehicleOption>>> getVehicleOptions() async {
    try {
      final res = await remoteDataSource.getVehicleOptions();
      return Right(res);
    } on WorkLogDataSourceException {
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<WorkLogRow>>> getWorks({
    required String vehicleId,
    required int from,
    required int to,
  }) async {
    try {
      final res = await remoteDataSource.getWorks(
        vehicleId: vehicleId,
        from: from,
        to: to,
      );
      return Right(res);
    } on WorkLogDataSourceException {
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
