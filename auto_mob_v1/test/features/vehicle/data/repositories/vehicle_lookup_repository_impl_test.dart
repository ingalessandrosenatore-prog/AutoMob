import 'package:auto_mob_v1/features/vehicle/data/datasources/vehicle_lookup_remote_data_source.dart';
import 'package:auto_mob_v1/features/vehicle/data/repositories/vehicle_lookup_repository_impl.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_lookup_result.dart';
import 'package:auto_mob_v1/features/vehicle/domain/failures/vehicle_lookup_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLookupDataSource extends Mock
    implements VehicleLookupRemoteDataSource {}

void main() {
  late MockLookupDataSource dataSource;
  late VehicleLookupRepositoryImpl repository;

  setUp(() {
    dataSource = MockLookupDataSource();
    repository = VehicleLookupRepositoryImpl(dataSource);
  });

  test('normalizza una targa valida prima della chiamata remota', () async {
    const found = VehicleLookupResult(
      lookupId: 'lookup-1',
      quality: VehicleLookupQuality.complete,
      plate: 'AB123CD',
    );
    when(
      () => dataSource.lookupByPlate('AB123CD'),
    ).thenAnswer((_) async => found);

    expect(await repository.lookupByPlate('ab 123-cd'), const Right(found));
    verify(() => dataSource.lookupByPlate('AB123CD')).called(1);
  });

  test('targa non valida: Left e nessuna chiamata a pagamento', () async {
    final result = await repository.lookupByPlate('ABC12');

    expect(result, const Left(InvalidPlateLookupFailure()));
    verifyNever(() => dataSource.lookupByPlate(any()));
  });

  test('propaga il failure tipizzato del data source', () async {
    when(
      () => dataSource.lookupByPlate('AB123CD'),
    ).thenThrow(const VehicleLookupDataSourceException(TimeoutLookupFailure()));

    expect(
      await repository.lookupByPlate('AB123CD'),
      const Left(TimeoutLookupFailure()),
    );
  });

  test('lookup meccanico inoltra codice e risultato', () async {
    const mechanic = MechanicSummary(
      id: 'm1',
      code: 'xxxxxx',
      businessName: 'Autofficina',
    );
    when(
      () => dataSource.lookupMechanicByCode('xxxxxx'),
    ).thenAnswer((_) async => mechanic);

    expect(
      await repository.lookupMechanicByCode('xxxxxx'),
      const Right(mechanic),
    );
  });
}
