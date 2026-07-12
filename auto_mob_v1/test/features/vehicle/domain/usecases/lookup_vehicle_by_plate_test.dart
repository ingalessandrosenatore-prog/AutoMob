// =====================================================================
//  GOLDEN TEST — USE CASE
// ---------------------------------------------------------------------
//  Pattern per testare uno use case: si mocka il repository (con mocktail)
//  e si verifica che lo use case inoltri la chiamata e propaghi il
//  risultato (sia il ramo Right sia il ramo Left di fpdart).
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_lookup_result.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_lookup_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/lookup_vehicle_by_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleLookupRepository extends Mock
    implements VehicleLookupRepository {}

void main() {
  late LookupVehicleByPlate usecase;
  late MockVehicleLookupRepository repository;

  setUp(() {
    repository = MockVehicleLookupRepository();
    usecase = LookupVehicleByPlate(repository);
  });

  const tTarga = 'AB123CD';
  const tResult = VehicleLookupResult(
    marca: 'Fiat',
    modello: 'Panda',
    anno: 2019,
    carburante: 'Benzina',
    cilindrata: 1242,
  );

  test(
    'inoltra la targa al repository e ritorna Right con i dati trovati',
    () async {
      when(
        () => repository.lookupByPlate(tTarga),
      ).thenAnswer((_) async => const Right(tResult));

      final result = await usecase(tTarga);

      expect(result, const Right<Failure, VehicleLookupResult>(tResult));
      verify(() => repository.lookupByPlate(tTarga)).called(1);
      verifyNoMoreInteractions(repository);
    },
  );

  test(
    'propaga il Failure quando il repository non trova il veicolo (Left)',
    () async {
      when(
        () => repository.lookupByPlate(tTarga),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await usecase(tTarga);

      expect(
        result,
        const Left<Failure, VehicleLookupResult>(NotFoundFailure()),
      );
    },
  );
}
