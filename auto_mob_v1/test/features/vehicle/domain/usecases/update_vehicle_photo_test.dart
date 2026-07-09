// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'dart:io';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_photo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

class FakeFile extends Fake implements File {}

void main() {
  late UpdateVehiclePhoto usecase;
  late MockVehicleRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    repository = MockVehicleRepository();
    usecase = UpdateVehiclePhoto(repository);
  });

  final tFile = File('veicolo_AB123CD.jpg');

  test('inoltra targa e foto al repository e ritorna Right quando salva',
      () async {
    when(() => repository.updateVehiclePhoto(targa: 'AB123CD', foto: tFile))
        .thenAnswer((_) async => const Right(null));

    final result = await usecase(targa: 'AB123CD', foto: tFile);

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.updateVehiclePhoto(targa: 'AB123CD', foto: tFile))
        .called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(() => repository.updateVehiclePhoto(targa: 'AB123CD', foto: tFile))
        .thenAnswer((_) async => const Left(StorageFailure()));

    final result = await usecase(targa: 'AB123CD', foto: tFile);

    expect(result, const Left<Failure, void>(StorageFailure()));
  });
}
