import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/failures/vehicle_lookup_failure.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_lookup_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/lookup_mechanic_by_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLookupRepository extends Mock implements VehicleLookupRepository {}

void main() {
  test('inoltra il codice e restituisce il meccanico attivo', () async {
    final repository = MockLookupRepository();
    const mechanic = MechanicSummary(
      id: 'mechanic-1',
      code: '482913',
      businessName: 'Autofficina Gommista GIORDANO',
    );
    when(
      () => repository.lookupMechanicByCode('482913'),
    ).thenAnswer((_) async => const Right(mechanic));

    expect(
      await LookupMechanicByCode(repository)(' 482913 '),
      const Right(mechanic),
    );
    verify(() => repository.lookupMechanicByCode('482913')).called(1);
  });

  test('rifiuta un codice non composto da sei cifre', () async {
    final repository = MockLookupRepository();

    expect(
      await LookupMechanicByCode(repository)('ABC123'),
      const Left(InvalidMechanicCodeLookupFailure()),
    );
    verifyNever(() => repository.lookupMechanicByCode(any()));
  });
}
