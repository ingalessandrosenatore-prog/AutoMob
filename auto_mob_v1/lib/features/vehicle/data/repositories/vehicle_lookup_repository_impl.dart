import 'package:fpdart/fpdart.dart';

import '../../domain/entities/mechanic_summary.dart';
import '../../domain/entities/vehicle_lookup_result.dart';
import '../../domain/failures/vehicle_lookup_failure.dart';
import '../../domain/repositories/vehicle_lookup_repository.dart';
import '../datasources/vehicle_lookup_remote_data_source.dart';

class VehicleLookupRepositoryImpl implements VehicleLookupRepository {
  final VehicleLookupRemoteDataSource remoteDataSource;

  const VehicleLookupRepositoryImpl(this.remoteDataSource);

  static String normalizePlate(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  static bool isValidItalianPlate(String value) =>
      RegExp(r'^[A-Z]{2}[0-9]{3}[A-Z]{2}$').hasMatch(normalizePlate(value));

  @override
  Future<Either<VehicleLookupFailure, VehicleLookupResult>> lookupByPlate(
    String targa,
  ) async {
    final normalized = normalizePlate(targa);
    if (!isValidItalianPlate(normalized)) {
      return const Left(InvalidPlateLookupFailure());
    }
    try {
      return Right(await remoteDataSource.lookupByPlate(normalized));
    } on VehicleLookupDataSourceException catch (e) {
      return Left(e.failure);
    }
  }

  @override
  Future<Either<VehicleLookupFailure, MechanicSummary?>> lookupMechanicByCode(
    String code,
  ) async {
    try {
      return Right(await remoteDataSource.lookupMechanicByCode(code));
    } on VehicleLookupDataSourceException catch (e) {
      return Left(e.failure);
    }
  }
}
