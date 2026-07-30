// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_km.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/km_update_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateVehicleKm extends Mock implements UpdateVehicleKm {}

void main() {
  late MockUpdateVehicleKm updateVehicleKm;

  setUp(() {
    updateVehicleKm = MockUpdateVehicleKm();
  });

  blocTest<KmUpdateCubit, KmUpdateState>(
    'emette [loading, success] quando l\'aggiornamento riesce',
    build: () {
      when(
        () => updateVehicleKm(vehicleId: 'v1', newKm: 15000),
      ).thenAnswer((_) async => const Right(15000));
      return KmUpdateCubit(updateVehicleKm);
    },
    act: (cubit) => cubit.aggiorna(vehicleId: 'v1', newKm: 15000),
    expect: () => const [
      KmUpdateState(status: KmUpdateStatus.loading),
      KmUpdateState(status: KmUpdateStatus.success, savedKm: 15000),
    ],
  );

  blocTest<KmUpdateCubit, KmUpdateState>(
    'emette [loading, failure] con un messaggio quando fallisce',
    build: () {
      when(
        () => updateVehicleKm(vehicleId: 'v1', newKm: 15000),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return KmUpdateCubit(updateVehicleKm);
    },
    act: (cubit) => cubit.aggiorna(vehicleId: 'v1', newKm: 15000),
    expect: () => [
      const KmUpdateState(status: KmUpdateStatus.loading),
      isA<KmUpdateState>()
          .having((s) => s.status, 'status', KmUpdateStatus.failure)
          .having((s) => s.error, 'error', isNotNull),
    ],
  );
}
