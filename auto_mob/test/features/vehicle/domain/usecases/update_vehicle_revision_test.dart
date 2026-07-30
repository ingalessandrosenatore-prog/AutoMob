import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_revision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late MockVehicleRepository repository;
  late UpdateVehicleRevision usecase;

  setUp(() {
    repository = MockVehicleRepository();
    usecase = UpdateVehicleRevision(repository);
  });

  test('inoltra veicolo e data al repository', () async {
    final date = DateTime(2028, 7, 16);
    when(
      () => repository.updateRevisionDate(
        vehicleId: 'v1',
        nextRevisionDate: date,
      ),
    ).thenAnswer((_) async => Right(date));

    final result = await usecase(vehicleId: 'v1', nextRevisionDate: date);

    expect(result, Right<Failure, DateTime>(date));
    verify(
      () => repository.updateRevisionDate(
        vehicleId: 'v1',
        nextRevisionDate: date,
      ),
    ).called(1);
  });

  test('propaga il failure del repository', () async {
    final date = DateTime(2028, 7, 16);
    when(
      () => repository.updateRevisionDate(
        vehicleId: 'v1',
        nextRevisionDate: date,
      ),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    final result = await usecase(vehicleId: 'v1', nextRevisionDate: date);

    expect(result, const Left<Failure, DateTime>(ServerFailure()));
  });
}
