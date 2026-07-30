// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/vehicle_option.dart';
import 'package:auto_mob_v1/features/work_log/domain/repositories/worklog_repo.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/get_vehicle_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWorklogRepo extends Mock implements WorklogRepo {}

void main() {
  late GetVehicleOptions usecase;
  late MockWorklogRepo repository;

  setUp(() {
    repository = MockWorklogRepo();
    usecase = GetVehicleOptions(repository);
  });

  const tOptions = [
    VehicleOption(id: 'v1', targa: 'AB123CD', nome: 'Panda', brand: 'Fiat', km: 10000),
  ];

  test('inoltra la richiesta al repository e ritorna la lista (Right)',
      () async {
    when(() => repository.getVehicleOptions())
        .thenAnswer((_) async => const Right(tOptions));

    final result = await usecase();

    expect(result, const Right<Failure, List<VehicleOption>>(tOptions));
    verify(() => repository.getVehicleOptions()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(() => repository.getVehicleOptions())
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase();

    expect(result, const Left<Failure, List<VehicleOption>>(ServerFailure()));
  });
}
