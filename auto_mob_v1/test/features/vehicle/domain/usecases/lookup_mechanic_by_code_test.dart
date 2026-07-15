import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
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
      code: 'xxxxxx',
      businessName: 'Autofficina Gommista GIORDANO',
    );
    when(
      () => repository.lookupMechanicByCode('xxxxxx'),
    ).thenAnswer((_) async => const Right(mechanic));

    expect(
      await LookupMechanicByCode(repository)('xxxxxx'),
      const Right(mechanic),
    );
    verify(() => repository.lookupMechanicByCode('xxxxxx')).called(1);
  });
}
