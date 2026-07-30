// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:auto_mob_v1/features/work_log/domain/repositories/worklog_repo.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/create_work_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWorklogRepo extends Mock implements WorklogRepo {}

void main() {
  late CreateWorkLog usecase;
  late MockWorklogRepo repository;

  setUp(() {
    repository = MockWorklogRepo();
    usecase = CreateWorkLog(repository);
  });

  final tServiceDate = DateTime(2026, 6, 16);
  const tItems = [SelectedPart(partId: 15, quantity: 1, unitPrice: 12.5)];

  test('inoltra i dati del lavoro al repository e ritorna Right', () async {
    when(() => repository.createWorkLog(
          vehicleId: 'v1',
          type: 'tagliando',
          customName: null,
          serviceKm: 50000,
          serviceDate: tServiceDate,
          notes: null,
          intervallKm: 15000,
          items: tItems,
        )).thenAnswer((_) async => const Right(null));

    final result = await usecase(
      vehicleId: 'v1',
      type: 'tagliando',
      serviceKm: 50000,
      serviceDate: tServiceDate,
      intervallKm: 15000,
      items: tItems,
    );

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.createWorkLog(
          vehicleId: 'v1',
          type: 'tagliando',
          customName: null,
          serviceKm: 50000,
          serviceDate: tServiceDate,
          notes: null,
          intervallKm: 15000,
          items: tItems,
        )).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(() => repository.createWorkLog(
          vehicleId: 'v1',
          type: 'tagliando',
          customName: null,
          serviceKm: 50000,
          serviceDate: tServiceDate,
          notes: null,
          intervallKm: 15000,
          items: tItems,
        )).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase(
      vehicleId: 'v1',
      type: 'tagliando',
      serviceKm: 50000,
      serviceDate: tServiceDate,
      intervallKm: 15000,
      items: tItems,
    );

    expect(result, const Left<Failure, void>(ServerFailure()));
  });
}
