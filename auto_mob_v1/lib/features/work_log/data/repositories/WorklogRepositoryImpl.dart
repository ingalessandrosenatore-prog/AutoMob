import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../../../../core/error/Exception/Exceptions.dart';
import '../../domain/entiti/SelectedPart.dart';
import '../../domain/entiti/VehicleOption.dart';
import '../../domain/entiti/WorkLogRow.dart';
import '../../domain/repositories/WorklogRepo.dart';
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
    } on WorkLogDataSourceException catch (e) {
      print("ERRORE SUPABASE WorkLog: ${e.message}");
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      print("ERRORE SCONOSCIUTO WorkLog: $e");
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<VehicleOption>>> getVehicleOptions() async {
    try {
      final res = await remoteDataSource.getVehicleOptions();
      return Right(res);
    } on WorkLogDataSourceException catch (e) {
      print("ERRORE SUPABASE WorkLog veicoli: ${e.message}");
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      print("ERRORE SCONOSCIUTO WorkLog veicoli: $e");
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
    } on WorkLogDataSourceException catch (e) {
      print("ERRORE SUPABASE WorkLog lavori: ${e.message}");
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      print("ERRORE SCONOSCIUTO WorkLog lavori: $e");
      return const Left(ServerFailure());
    }
  }
}
