import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/load_vehicle_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  test('inoltra il caricamento della bozza al repository', () async {
    final repository = MockVehicleRepository();
    const draft = VehicleDraft(targa: 'AB123CD');
    when(
      () => repository.loadDraft(),
    ).thenAnswer((_) async => const Right(draft));

    expect(await LoadVehicleDraft(repository)(), const Right(draft));
    verify(() => repository.loadDraft()).called(1);
  });
}
