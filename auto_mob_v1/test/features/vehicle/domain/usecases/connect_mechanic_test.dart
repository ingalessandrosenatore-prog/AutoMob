import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/connect_mechanic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late MockVehicleRepository repository;
  late ConnectMechanic usecase;

  const mechanic = MechanicSummary(
    id: 'mechanic-1',
    code: 'OFF-001',
    businessName: 'Officina Giordano',
  );

  setUp(() {
    repository = MockVehicleRepository();
    usecase = ConnectMechanic(repository);
  });

  test(
    'normalizza il codice e inoltra il collegamento al repository',
    () async {
      when(
        () => repository.connectMechanic(
          vehicleId: 'vehicle-1',
          mechanicCode: 'OFF-001',
        ),
      ).thenAnswer((_) async => const Right(mechanic));

      final result = await usecase(
        vehicleId: 'vehicle-1',
        mechanicCode: '  OFF-001  ',
      );

      expect(result, const Right<Failure, MechanicSummary>(mechanic));
      verify(
        () => repository.connectMechanic(
          vehicleId: 'vehicle-1',
          mechanicCode: 'OFF-001',
        ),
      ).called(1);
    },
  );

  test('rifiuta un codice vuoto senza interrogare il repository', () async {
    final result = await usecase(vehicleId: 'vehicle-1', mechanicCode: '   ');

    expect(
      result,
      const Left<Failure, MechanicSummary>(
        ValidationFailure('Inserisci il codice del meccanico.'),
      ),
    );
    verifyNever(
      () => repository.connectMechanic(
        vehicleId: any(named: 'vehicleId'),
        mechanicCode: any(named: 'mechanicCode'),
      ),
    );
  });
}
