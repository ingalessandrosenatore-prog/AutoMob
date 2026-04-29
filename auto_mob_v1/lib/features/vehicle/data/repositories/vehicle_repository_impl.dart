import 'package:fpdart/fpdart.dart';

import '../../../../core/error/Exception/Exception.dart';
import '../../../../core/error/Exception/Exceptions.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/repositories/VehicleRepository.dart';
import '../datasources/vehicle_draft_local_data_source.dart';
import '../datasources/vehicle_remote_data_source.dart';
import '../models/vehicle_draft_model.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleDraftLocalDataSource localDataSource;
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, void>> saveDraftStep(VehicleDraft draft) async {
    try {
      final model = VehicleDraftModel.fromDraft(draft);
      await localDataSource.saveDraft(model);
      return const Right(null);
    } on CacheException {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveVehicle(VehicleDraft draft) async {
    try {
      // Ora aspettiamo un booleano (o un'eccezione se fallisce)
      await remoteDataSource.saveVehicle(draft);
      return const Right(null);
    } on VehicleDataSourceException catch (e) {
      // QUESTO È IL TUO SALVAVITA: ti dirà ESATTAMENTE quale constraint fallisce
      print("ERRORE SUPABASE: ${e.message} - Dettagli: ");
      return Left(ServerFailure());
    } catch (e) {
      print("ERRORE SCONOSCIUTO: $e");
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async {
    try {
      final vehicles = await remoteDataSource.getVehicles();
      return Right(vehicles);
    } on VehicleDataSourceException {
      return Left(const ServerFailure());
    } on NetworkException {
      return Left(const NetworkFailure());
    }
  }
}
