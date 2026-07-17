import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/core/error/exceptions/exceptions.dart';
import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_draft_local_data_source.dart';
import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import 'package:auto_mob_v1/features/vehicle/data/repositories/vehicle_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements VehicleRemoteDataSource {}

class MockLocal extends Mock implements VehicleDraftLocalDataSource {}

void main() {
  late MockRemote remote;
  late VehicleRepositoryImpl repository;
  final date = DateTime(2028, 7, 16);

  setUp(() {
    remote = MockRemote();
    repository = VehicleRepositoryImpl(
      localDataSource: MockLocal(),
      remoteDataSource: remote,
    );
  });

  test('ritorna la data salvata dal datasource', () async {
    when(
      () => remote.updateRevisionDate(vehicleId: 'v1', nextRevisionDate: date),
    ).thenAnswer((_) async => date);

    final result = await repository.updateRevisionDate(
      vehicleId: 'v1',
      nextRevisionDate: date,
    );

    expect(result, Right<Failure, DateTime>(date));
  });

  test('mappa gli errori remoti nei failure corretti', () async {
    when(
      () => remote.updateRevisionDate(vehicleId: 'v1', nextRevisionDate: date),
    ).thenThrow(const NetworkException());

    final networkResult = await repository.updateRevisionDate(
      vehicleId: 'v1',
      nextRevisionDate: date,
    );
    expect(networkResult, const Left<Failure, DateTime>(NetworkFailure()));

    when(
      () => remote.updateRevisionDate(vehicleId: 'v1', nextRevisionDate: date),
    ).thenThrow(const VehicleDataSourceException('boom', code: 'PGRST202'));

    final serverResult = await repository.updateRevisionDate(
      vehicleId: 'v1',
      nextRevisionDate: date,
    );
    expect(
      serverResult,
      const Left<Failure, DateTime>(
        RemoteFailure('boom\nCodice: PGRST202', code: 'PGRST202'),
      ),
    );
  });
}
