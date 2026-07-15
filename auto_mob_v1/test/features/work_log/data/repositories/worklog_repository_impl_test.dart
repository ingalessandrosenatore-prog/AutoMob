// =====================================================================
//  GOLDEN TEST — REPOSITORY (layer data)
// ---------------------------------------------------------------------
//  Pattern per testare un repository: si mocka il datasource (NON si
//  tocca DB/rete) e si verifica la mappatura Exception -> Failure e il
//  passaggio dei valori.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/core/error/exceptions/exceptions.dart';
import 'package:auto_mob_v1/features/work_log/data/datasources/worklog_remote_data_source.dart';
import 'package:auto_mob_v1/features/work_log/data/models/vehicle_option_model.dart';
import 'package:auto_mob_v1/features/work_log/data/models/work_log_row_model.dart';
import 'package:auto_mob_v1/features/work_log/data/repositories/worklog_repository_impl.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/vehicle_option.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/work_log_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWorklogRemoteDataSource extends Mock
    implements WorklogRemoteDataSource {}

void main() {
  late WorklogRepositoryImpl repository;
  late MockWorklogRemoteDataSource remote;

  setUp(() {
    remote = MockWorklogRemoteDataSource();
    repository = WorklogRepositoryImpl(remoteDataSource: remote);
  });

  final tServiceDate = DateTime(2026, 6, 16);
  const tItems = [SelectedPart(partId: 15, quantity: 1, unitPrice: 12.5)];

  group('createWorkLog', () {
    test('ritorna Right(null) quando il datasource risponde', () async {
      when(
        () => remote.createWorkLog(
          vehicleId: 'v1',
          type: 'tagliando',
          customName: null,
          serviceKm: 50000,
          serviceDate: tServiceDate,
          notes: null,
          intervallKm: 15000,
          items: tItems,
        ),
      ).thenAnswer((_) async {});

      final result = await repository.createWorkLog(
        vehicleId: 'v1',
        type: 'tagliando',
        serviceKm: 50000,
        serviceDate: tServiceDate,
        intervallKm: 15000,
        items: tItems,
      );

      expect(result, const Right<Failure, void>(null));
    });

    test('mappa WorkLogDataSourceException in ServerFailure', () async {
      when(
        () => remote.createWorkLog(
          vehicleId: 'v1',
          type: 'tagliando',
          customName: null,
          serviceKm: 50000,
          serviceDate: tServiceDate,
          notes: null,
          intervallKm: 15000,
          items: tItems,
        ),
      ).thenThrow(const WorkLogDataSourceException('boom'));

      final result = await repository.createWorkLog(
        vehicleId: 'v1',
        type: 'tagliando',
        serviceKm: 50000,
        serviceDate: tServiceDate,
        intervallKm: 15000,
        items: tItems,
      );

      expect(result, const Left<Failure, void>(CodedServerFailure()));
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(
        () => remote.createWorkLog(
          vehicleId: 'v1',
          type: 'tagliando',
          customName: null,
          serviceKm: 50000,
          serviceDate: tServiceDate,
          notes: null,
          intervallKm: 15000,
          items: tItems,
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.createWorkLog(
        vehicleId: 'v1',
        type: 'tagliando',
        serviceKm: 50000,
        serviceDate: tServiceDate,
        intervallKm: 15000,
        items: tItems,
      );

      expect(result, const Left<Failure, void>(NetworkFailure()));
    });
  });

  group('getVehicleOptions', () {
    final tOptions = [
      const VehicleOptionModel(
        id: 'v1',
        targa: 'AB123CD',
        nome: 'Panda',
        brand: 'Fiat',
        km: 10000,
      ),
    ];

    test('ritorna Right con la lista quando il datasource risponde', () async {
      when(() => remote.getVehicleOptions()).thenAnswer((_) async => tOptions);

      final result = await repository.getVehicleOptions();

      expect(result, Right<Failure, List<VehicleOption>>(tOptions));
    });

    test('mappa WorkLogDataSourceException in ServerFailure', () async {
      when(
        () => remote.getVehicleOptions(),
      ).thenThrow(const WorkLogDataSourceException('boom'));

      final result = await repository.getVehicleOptions();

      expect(result, const Left<Failure, List<VehicleOption>>(ServerFailure()));
    });
  });

  group('getWorks', () {
    final tWorks = [
      WorkLogRowModel(
        id: 'w1',
        type: 'tagliando',
        serviceKm: 50000,
        serviceDate: tServiceDate,
        hasWorkshop: true,
      ),
    ];

    test('ritorna Right con la pagina quando il datasource risponde', () async {
      when(
        () => remote.getWorks(vehicleId: 'v1', from: 0, to: 19),
      ).thenAnswer((_) async => tWorks);

      final result = await repository.getWorks(
        vehicleId: 'v1',
        from: 0,
        to: 19,
      );

      expect(result, Right<Failure, List<WorkLogRow>>(tWorks));
    });

    test('mappa NetworkException in NetworkFailure', () async {
      when(
        () => remote.getWorks(vehicleId: 'v1', from: 0, to: 19),
      ).thenThrow(const NetworkException());

      final result = await repository.getWorks(
        vehicleId: 'v1',
        from: 0,
        to: 19,
      );

      expect(result, const Left<Failure, List<WorkLogRow>>(NetworkFailure()));
    });
  });
}
