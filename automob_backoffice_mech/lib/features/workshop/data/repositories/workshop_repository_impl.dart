import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/workshop_catalog.dart';
import '../../domain/repositories/workshop_repository.dart';
import '../datasources/workshop_remote_data_source.dart';

final class WorkshopRepositoryImpl implements WorkshopRepository {
  const WorkshopRepositoryImpl(this.remoteDataSource);

  final WorkshopRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, WorkshopCatalog>> getCatalog() async {
    try {
      final model = await remoteDataSource.getCatalog();
      return Right(model.toEntity());
    } on SocketException {
      return const Left(NetworkFailure());
    } on WorkshopDataException catch (error) {
      if (error.code == '42501') return const Left(PermissionFailure());
      return const Left(ServerFailure());
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
