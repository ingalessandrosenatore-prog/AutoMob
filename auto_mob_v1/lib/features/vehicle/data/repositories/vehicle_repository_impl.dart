import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions/exception.dart';
import '../../../../core/error/exceptions/exceptions.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/entities/vehicle_save_outcome.dart';
import '../../domain/repositories/vehicle_repository.dart';
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
  Future<Either<Failure, VehicleDraft?>> loadDraft() async {
    try {
      return Right(await localDataSource.loadDraft());
    } on CacheException {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> clearDraft() async {
    try {
      await localDataSource.clearDraft();
      return const Right(null);
    } on CacheException {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<Either<Failure, VehicleSaveOutcome>> saveVehicle(
    VehicleDraft draft,
  ) async {
    try {
      final vehicleId = await remoteDataSource.saveVehicle(draft);

      var photoSaved = true;
      if (draft.fotoFile != null && draft.targa!.isNotEmpty) {
        try {
          await localDataSource.saveFoto(draft.fotoFile!, draft.targa!);
        } on CacheException {
          // Il record remoto è già stato creato: non restituiamo un errore che
          // indurrebbe il BLoC a rilanciare l'RPC e creare un duplicato.
          photoSaved = false;
        }
      }
      return Right(
        VehicleSaveOutcome(vehicleId: vehicleId, photoSaved: photoSaved),
      );
    } on VehicleDataSourceException {
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, int>> updateKm({
    required String vehicleId,
    required int newKm,
  }) async {
    try {
      final kmSalvati = await remoteDataSource.updateKm(
        vehicleId: vehicleId,
        newKm: newKm,
      );
      return Right(kmSalvati);
    } on VehicleDataSourceException {
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateVehiclePhoto({
    required String targa,
    required File foto,
  }) async {
    try {
      await localDataSource.saveFoto(foto, targa);
      return const Right(null);
    } on CacheException {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async {
    try {
      final vehicles = await remoteDataSource.getVehicles();
      final vehiclesWithFoto = vehicles.map((v) {
        final path = localDataSource.getFotoPath(v.plate);
        return v.copyWith(fotoPath: path);
      }).toList();
      return Right(vehiclesWithFoto);
    } on VehicleDataSourceException {
      return const Left(ServerFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }
}
