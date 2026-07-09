// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_km.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late UpdateVehicleKm usecase;
  late MockVehicleRepository repository;

  setUp(() {
    repository = MockVehicleRepository();
    usecase = UpdateVehicleKm(repository);
  });

  test('inoltra vehicleId e newKm al repository e ritorna i km salvati (Right)',
      () async {
    when(() => repository.updateKm(vehicleId: 'v1', newKm: 15000))
        .thenAnswer((_) async => const Right(15000));

    final result = await usecase(vehicleId: 'v1', newKm: 15000);

    expect(result, const Right<Failure, int>(15000));
    verify(() => repository.updateKm(vehicleId: 'v1', newKm: 15000)).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    when(() => repository.updateKm(vehicleId: 'v1', newKm: 15000))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase(vehicleId: 'v1', newKm: 15000);

    expect(result, const Left<Failure, int>(ServerFailure()));
  });
}
