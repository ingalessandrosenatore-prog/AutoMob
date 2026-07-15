import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_lookup_result.dart';
import 'package:auto_mob_v1/features/vehicle/domain/failures/vehicle_lookup_failure.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_lookup_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/lookup_vehicle_by_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLookupRepository extends Mock implements VehicleLookupRepository {}

void main() {
  late MockLookupRepository repository;
  late LookupVehicleByPlate usecase;
  setUp(() {
    repository = MockLookupRepository();
    usecase = LookupVehicleByPlate(repository);
  });

  test('propaga il Right del repository', () async {
    const found = VehicleLookupResult(
      lookupId: 'id',
      quality: VehicleLookupQuality.partial,
      plate: 'AA000AA',
    );
    when(
      () => repository.lookupByPlate('AA000AA'),
    ).thenAnswer((_) async => const Right(found));
    expect(await usecase('AA000AA'), const Right(found));
  });

  test('propaga il Left tipizzato del repository', () async {
    when(
      () => repository.lookupByPlate('AB123CD'),
    ).thenAnswer((_) async => const Left(NetworkLookupFailure()));
    expect(await usecase('AB123CD'), const Left(NetworkLookupFailure()));
  });
}
