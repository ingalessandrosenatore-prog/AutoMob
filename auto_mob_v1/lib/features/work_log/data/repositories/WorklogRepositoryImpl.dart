import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../../../../core/error/Exception/Exceptions.dart';
import '../../domain/entiti/WorkLogItemEntity.dart';
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
    required List<WorkLogItem> items,
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
}
