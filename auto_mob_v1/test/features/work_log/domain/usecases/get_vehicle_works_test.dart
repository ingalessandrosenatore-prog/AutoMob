// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/work_log_row.dart';
import 'package:auto_mob_v1/features/work_log/domain/repositories/worklog_repo.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/get_vehicle_works.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWorklogRepo extends Mock implements WorklogRepo {}

void main() {
  late GetVehicleWorks usecase;
  late MockWorklogRepo repository;

  setUp(() {
    repository = MockWorklogRepo();
    usecase = GetVehicleWorks(repository);
  });

  final tWorks = [
    WorkLogRow(
      id: 'w1',
      type: 'tagliando',
      serviceKm: 50000,
      serviceDate: DateTime(2026, 6, 16),
      hasWorkshop: true,
    ),
  ];

  test('inoltra vehicleId/from/to al repository e ritorna la pagina (Right)',
      () async {
    when(() => repository.getWorks(vehicleId: 'v1', from: 0, to: 19))
        .thenAnswer((_) async => Right(tWorks));

    final result = await usecase(vehicleId: 'v1', from: 0, to: 19);

    expect(result, Right<Failure, List<WorkLogRow>>(tWorks));
    verify(() => repository.getWorks(vehicleId: 'v1', from: 0, to: 19))
        .called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(() => repository.getWorks(vehicleId: 'v1', from: 0, to: 19))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase(vehicleId: 'v1', from: 0, to: 19);

    expect(result, const Left<Failure, List<WorkLogRow>>(ServerFailure()));
  });
}
