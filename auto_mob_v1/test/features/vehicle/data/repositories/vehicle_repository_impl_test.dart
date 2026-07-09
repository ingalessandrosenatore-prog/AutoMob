// =====================================================================
//  GOLDEN TEST — REPOSITORY (layer data)
// ---------------------------------------------------------------------
//  Pattern per testare un repository: si mockano i datasource (NON si
//  tocca DB/rete) e si verifica la mappatura Exception -> Failure e il
//  passaggio dei valori. Qui usiamo updateKm come esempio.
// =====================================================================

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
  late VehicleRepositoryImpl repository;
  late MockRemote remote;
  late MockLocal local;

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repository = VehicleRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  group('updateKm', () {
    test('ritorna Right con i km salvati quando il datasource risponde',
        () async {
      when(() => remote.updateKm(vehicleId: 'v1', newKm: 12000))
          .thenAnswer((_) async => 12345);

      final result = await repository.updateKm(vehicleId: 'v1', newKm: 12000);

      expect(result, const Right<Failure, int>(12345));
      verify(() => remote.updateKm(vehicleId: 'v1', newKm: 12000)).called(1);
    });

    test('mappa VehicleDataSourceException in ServerFailure', () async {
      when(() => remote.updateKm(vehicleId: 'v1', newKm: 12000))
          .thenThrow(const VehicleDataSourceException('boom'));

      final result = await repository.updateKm(vehicleId: 'v1', newKm: 12000);

      expect(result, const Left<Failure, int>(ServerFailure()));
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(() => remote.updateKm(vehicleId: 'v1', newKm: 12000))
          .thenThrow(const NetworkException());

      final result = await repository.updateKm(vehicleId: 'v1', newKm: 12000);

      expect(result, const Left<Failure, int>(NetworkFailure()));
    });
  });
}
