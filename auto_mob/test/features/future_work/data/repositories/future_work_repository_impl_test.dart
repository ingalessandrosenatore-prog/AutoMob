import 'dart:io';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/future_work/data/datasources/future_work_remote_data_source.dart';
import 'package:auto_mob_v1/features/future_work/data/repositories/future_work_repository_impl.dart';
import 'package:auto_mob_v1/features/future_work/data/models/future_work_summary_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFutureWorkRemoteDataSource extends Mock
    implements FutureWorkRemoteDataSource {}

void main() {
  late _MockFutureWorkRemoteDataSource dataSource;
  late FutureWorkRepositoryImpl repository;
  final deadline = DateTime(2026, 9, 20);

  setUp(() {
    dataSource = _MockFutureWorkRemoteDataSource();
    repository = FutureWorkRepositoryImpl(dataSource);
  });

  test('restituisce il report creato dal datasource', () async {
    when(
      () => dataSource.createReport(
        vehicleId: 'v1',
        description: 'Freni',
        reminderDate: deadline,
      ),
    ).thenAnswer((_) async => 'r1');

    final result = await repository.createReport(
      vehicleId: 'v1',
      description: 'Freni',
      reminderDate: deadline,
    );

    expect(result.isRight(), isTrue);
    expect(result.toNullable()?.id, 'r1');
  });

  test('restituisce le ultime segnalazioni aperte', () async {
    final summary = FutureWorkSummaryModel(
      id: 'i1',
      recordId: 'r1',
      vehicleId: 'v1',
      description: 'Freni',
      registeredAt: DateTime(2026, 9, 17),
      reminderDate: deadline,
    );
    when(() => dataSource.getLatestOpen()).thenAnswer((_) async => [summary]);

    final result = await repository.getLatestOpen();

    expect(result.toNullable(), [summary]);
  });

  test('mappa rete, permessi e validazione in failure di dominio', () async {
    when(
      () => dataSource.createReport(
        vehicleId: any(named: 'vehicleId'),
        description: any(named: 'description'),
        reminderDate: any(named: 'reminderDate'),
      ),
    ).thenThrow(const SocketException('offline'));
    final network = await repository.createReport(
      vehicleId: 'v1',
      description: 'Freni',
      reminderDate: deadline,
    );
    expect(network.getLeft().toNullable(), isA<NetworkFailure>());

    when(
      () => dataSource.createReport(
        vehicleId: any(named: 'vehicleId'),
        description: any(named: 'description'),
        reminderDate: any(named: 'reminderDate'),
      ),
    ).thenThrow(const FutureWorkDataSourceException('vietato', code: '42501'));
    final permission = await repository.createReport(
      vehicleId: 'v1',
      description: 'Freni',
      reminderDate: deadline,
    );
    expect(permission.getLeft().toNullable(), isA<PermissionFailure>());
  });
}
