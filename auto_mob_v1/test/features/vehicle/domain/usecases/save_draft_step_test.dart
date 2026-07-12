// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/save_draft_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late SaveDraftStep usecase;
  late MockVehicleRepository repository;

  setUp(() {
    repository = MockVehicleRepository();
    usecase = SaveDraftStep(repository);
  });

  const tDraft = VehicleDraft(targa: 'AB123CD', marca: 'Fiat');

  test('inoltra il draft al repository e ritorna Right', () async {
    when(
      () => repository.saveDraftStep(tDraft),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(tDraft);

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.saveDraftStep(tDraft)).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(
      () => repository.saveDraftStep(tDraft),
    ).thenAnswer((_) async => const Left(StorageFailure()));

    final result = await usecase(tDraft);

    expect(result, const Left<Failure, void>(StorageFailure()));
  });
}
