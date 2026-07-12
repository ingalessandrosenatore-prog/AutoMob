// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/get_vehicles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

// Il mock del repository: implementa l'interfaccia del domain senza toccare DB.
class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late GetVehicles usecase;
  late MockVehicleRepository repository;

  setUp(() {
    repository = MockVehicleRepository();
    usecase = GetVehicles(repository);
  });

  final tVehicles = <Vehicle>[vehicleFixture()];

  test(
    'inoltra la richiesta al repository e ritorna la lista (Right)',
    () async {
      // arrange
      when(
        () => repository.getVehicles(),
      ).thenAnswer((_) async => Right(tVehicles));

      // act
      final result = await usecase();

      // assert
      expect(result, Right<Failure, List<Vehicle>>(tVehicles));
      verify(() => repository.getVehicles()).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test('propaga il Failure quando il repository fallisce (Left)', () async {
    // arrange
    when(
      () => repository.getVehicles(),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    // act
    final result = await usecase();

    // assert
    expect(result, const Left<Failure, List<Vehicle>>(ServerFailure()));
  });
}
