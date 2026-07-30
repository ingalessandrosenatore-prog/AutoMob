import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/clear_vehicle_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  test('inoltra la cancellazione della bozza al repository', () async {
    final repository = MockVehicleRepository();
    when(
      () => repository.clearDraft(),
    ).thenAnswer((_) async => const Right(null));

    expect(await ClearVehicleDraft(repository)(), const Right(null));
    verify(() => repository.clearDraft()).called(1);
  });
}
