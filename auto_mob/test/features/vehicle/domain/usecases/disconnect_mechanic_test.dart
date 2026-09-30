import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/disconnect_mechanic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late MockVehicleRepository repository;
  late DisconnectMechanic usecase;

  setUp(() {
    repository = MockVehicleRepository();
    usecase = DisconnectMechanic(repository);
  });

  test('inoltra gli identificativi al repository', () async {
    when(
      () => repository.disconnectMechanic(
        vehicleId: 'vehicle-1',
        mechanicId: 'mechanic-1',
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(
      vehicleId: 'vehicle-1',
      mechanicId: 'mechanic-1',
    );

    expect(result, const Right<Failure, void>(null));
  });

  test('rifiuta identificativi vuoti senza chiamare il repository', () async {
    final result = await usecase(vehicleId: '', mechanicId: 'mechanic-1');

    expect(
      result,
      const Left<Failure, void>(
        ValidationFailure('Officina o veicolo non valido.'),
      ),
    );
    verifyNever(
      () => repository.disconnectMechanic(
        vehicleId: any(named: 'vehicleId'),
        mechanicId: any(named: 'mechanicId'),
      ),
    );
  });
}
