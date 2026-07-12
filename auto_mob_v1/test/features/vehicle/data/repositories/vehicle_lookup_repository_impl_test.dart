// =====================================================================
//  GOLDEN TEST — REPOSITORY IMPL (mock, nessuna chiamata reale)
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/data/repositories/vehicle_lookup_repository_impl.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_lookup_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  late VehicleLookupRepositoryImpl repository;

  setUp(() {
    repository = VehicleLookupRepositoryImpl();
  });

  test('ritorna Right con dati mock per una targa qualsiasi', () async {
    final result = await repository.lookupByPlate('AB123CD');

    expect(
      result,
      const Right<Failure, VehicleLookupResult>(
        VehicleLookupResult(
          marca: 'Fiat',
          modello: 'Panda',
          anno: 2019,
          carburante: 'Benzina',
          cilindrata: 1242,
        ),
      ),
    );
  });

  test(
    'ritorna Left(NotFoundFailure) quando la targa contiene "FAIL"',
    () async {
      final result = await repository.lookupByPlate('FAIL123');

      expect(
        result,
        const Left<Failure, VehicleLookupResult>(NotFoundFailure()),
      );
    },
  );

  test('il match su "FAIL" e\' case-insensitive', () async {
    final result = await repository.lookupByPlate('fail999');

    expect(result, const Left<Failure, VehicleLookupResult>(NotFoundFailure()));
  });
}
