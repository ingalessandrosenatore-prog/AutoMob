// =====================================================================
//  GOLDEN TEST — REPOSITORY (layer data)
// ---------------------------------------------------------------------
//  Pattern per testare un repository: si mockano i datasource (NON si
//  tocca DB/rete) e si verifica la mappatura Exception -> Failure e il
//  passaggio dei valori. Qui usiamo updateKm come esempio.
// =====================================================================

import 'dart:io';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/core/error/exceptions/exceptions.dart';
import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_draft_local_data_source.dart';
import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import 'package:auto_mob_v1/features/vehicle/data/repositories/vehicle_repository_impl.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements VehicleRemoteDataSource {}

class MockLocal extends Mock implements VehicleDraftLocalDataSource {}

class FakeFile extends Fake implements File {}

void main() {
  late VehicleRepositoryImpl repository;
  late MockRemote remote;
  late MockLocal local;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    repository = VehicleRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  group('updateKm', () {
    test(
      'ritorna Right con i km salvati quando il datasource risponde',
      () async {
        when(
          () => remote.updateKm(vehicleId: 'v1', newKm: 12000),
        ).thenAnswer((_) async => 12345);

        final result = await repository.updateKm(vehicleId: 'v1', newKm: 12000);

        expect(result, const Right<Failure, int>(12345));
        verify(() => remote.updateKm(vehicleId: 'v1', newKm: 12000)).called(1);
      },
    );

    test('mappa VehicleDataSourceException in ServerFailure', () async {
      when(
        () => remote.updateKm(vehicleId: 'v1', newKm: 12000),
      ).thenThrow(const VehicleDataSourceException('boom'));

      final result = await repository.updateKm(vehicleId: 'v1', newKm: 12000);

      expect(result, const Left<Failure, int>(ServerFailure()));
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(
        () => remote.updateKm(vehicleId: 'v1', newKm: 12000),
      ).thenThrow(const NetworkException());

      final result = await repository.updateKm(vehicleId: 'v1', newKm: 12000);

      expect(result, const Left<Failure, int>(NetworkFailure()));
    });
  });

  group('connectMechanic', () {
    const mechanic = MechanicSummary(
      id: 'mechanic-1',
      code: 'OFF-001',
      businessName: 'Officina Giordano',
    );

    test('ritorna il meccanico collegato dal datasource', () async {
      when(
        () => remote.connectMechanic(
          vehicleId: 'vehicle-1',
          mechanicCode: 'OFF-001',
        ),
      ).thenAnswer((_) async => mechanic);

      final result = await repository.connectMechanic(
        vehicleId: 'vehicle-1',
        mechanicCode: 'OFF-001',
      );

      expect(result, const Right<Failure, MechanicSummary>(mechanic));
    });

    test('mappa un codice sconosciuto in ValidationFailure', () async {
      when(
        () => remote.connectMechanic(
          vehicleId: 'vehicle-1',
          mechanicCode: 'ERRATO',
        ),
      ).thenThrow(
        const VehicleDataSourceException(
          'non trovato',
          code: 'mechanic_not_found',
        ),
      );

      final result = await repository.connectMechanic(
        vehicleId: 'vehicle-1',
        mechanicCode: 'ERRATO',
      );

      expect(
        result,
        const Left<Failure, MechanicSummary>(
          ValidationFailure(
            'Codice meccanico non valido o officina non attiva.',
          ),
        ),
      );
    });

    test('mappa un collegamento duplicato in DuplicateFailure', () async {
      when(
        () => remote.connectMechanic(
          vehicleId: 'vehicle-1',
          mechanicCode: 'OFF-001',
        ),
      ).thenThrow(const VehicleDataSourceException('duplicato', code: '23505'));

      final result = await repository.connectMechanic(
        vehicleId: 'vehicle-1',
        mechanicCode: 'OFF-001',
      );

      expect(
        result,
        const Left<Failure, MechanicSummary>(
          DuplicateFailure('Questo meccanico e gia collegato al veicolo.'),
        ),
      );
    });

    test('mappa l’assenza di rete in NetworkFailure', () async {
      when(
        () => remote.connectMechanic(
          vehicleId: 'vehicle-1',
          mechanicCode: 'OFF-001',
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.connectMechanic(
        vehicleId: 'vehicle-1',
        mechanicCode: 'OFF-001',
      );

      expect(result, const Left<Failure, MechanicSummary>(NetworkFailure()));
    });
  });

  group('disconnectMechanic', () {
    test('ritorna Right dopo aver eliminato il collegamento', () async {
      when(
        () => remote.disconnectMechanic(
          vehicleId: 'vehicle-1',
          mechanicId: 'mechanic-1',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.disconnectMechanic(
        vehicleId: 'vehicle-1',
        mechanicId: 'mechanic-1',
      );

      expect(result, const Right<Failure, void>(null));
      verify(
        () => remote.disconnectMechanic(
          vehicleId: 'vehicle-1',
          mechanicId: 'mechanic-1',
        ),
      ).called(1);
    });

    test('mappa un errore di rete in NetworkFailure', () async {
      when(
        () => remote.disconnectMechanic(
          vehicleId: 'vehicle-1',
          mechanicId: 'mechanic-1',
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.disconnectMechanic(
        vehicleId: 'vehicle-1',
        mechanicId: 'mechanic-1',
      );

      expect(result, const Left<Failure, void>(NetworkFailure()));
    });
  });

  group('updateVehiclePhoto', () {
    final tFile = File('veicolo_AB123CD.jpg');

    test('ritorna Right e riusa saveFoto con la stessa targa', () async {
      when(() => local.saveFoto(tFile, 'AB123CD')).thenAnswer((_) async {});

      final result = await repository.updateVehiclePhoto(
        targa: 'AB123CD',
        foto: tFile,
      );

      expect(result, const Right<Failure, void>(null));
      verify(() => local.saveFoto(tFile, 'AB123CD')).called(1);
    });

    test('mappa CacheException in StorageFailure', () async {
      when(
        () => local.saveFoto(tFile, 'AB123CD'),
      ).thenThrow(const CacheException('boom'));

      final result = await repository.updateVehiclePhoto(
        targa: 'AB123CD',
        foto: tFile,
      );

      expect(result, const Left<Failure, void>(StorageFailure()));
    });
  });
}
