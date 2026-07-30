import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_revision.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/revision_update_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateVehicleRevision extends Mock implements UpdateVehicleRevision {}

void main() {
  late MockUpdateVehicleRevision updateVehicleRevision;
  final date = DateTime(2028, 7, 16);

  setUp(() {
    updateVehicleRevision = MockUpdateVehicleRevision();
  });

  blocTest<RevisionUpdateCubit, RevisionUpdateState>(
    'emette loading e success con la data salvata',
    build: () {
      when(
        () => updateVehicleRevision(vehicleId: 'v1', nextRevisionDate: date),
      ).thenAnswer((_) async => Right(date));
      return RevisionUpdateCubit(updateVehicleRevision);
    },
    seed: () => RevisionUpdateState(selectedDate: date),
    act: (cubit) => cubit.aggiorna(vehicleId: 'v1'),
    expect: () => [
      RevisionUpdateState(
        status: RevisionUpdateStatus.loading,
        selectedDate: date,
      ),
      RevisionUpdateState(
        status: RevisionUpdateStatus.success,
        savedDate: date,
        selectedDate: date,
      ),
    ],
  );

  blocTest<RevisionUpdateCubit, RevisionUpdateState>(
    'emette loading e failure quando il salvataggio fallisce',
    build: () {
      when(
        () => updateVehicleRevision(vehicleId: 'v1', nextRevisionDate: date),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return RevisionUpdateCubit(updateVehicleRevision);
    },
    seed: () => RevisionUpdateState(selectedDate: date),
    act: (cubit) => cubit.aggiorna(vehicleId: 'v1'),
    expect: () => [
      RevisionUpdateState(
        status: RevisionUpdateStatus.loading,
        selectedDate: date,
      ),
      isA<RevisionUpdateState>()
          .having(
            (state) => state.status,
            'status',
            RevisionUpdateStatus.failure,
          )
          .having((state) => state.error, 'error', isNotNull),
    ],
  );
}
