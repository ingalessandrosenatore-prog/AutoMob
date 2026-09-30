// =====================================================================
//  GOLDEN TEST — CUBIT / BLoC (layer presentation)
// ---------------------------------------------------------------------
//  Pattern per testare un Cubit/BLoC: si mocka lo use case (con mocktail)
//  e con blocTest si dichiara la SEQUENZA di stati attesa dopo un'azione.
// =====================================================================

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_km.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/add_fuel_expense.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/fuel_expense_draft.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/km_update_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateVehicleKm extends Mock implements UpdateVehicleKm {}

class MockAddFuelExpense extends Mock implements AddFuelExpense {}

void main() {
  late MockUpdateVehicleKm updateVehicleKm;
  late MockAddFuelExpense addFuelExpense;

  setUpAll(() {
    registerFallbackValue(const FuelExpenseDraft(costCents: 1, litersMilli: 1));
  });

  setUp(() {
    updateVehicleKm = MockUpdateVehicleKm();
    addFuelExpense = MockAddFuelExpense();
  });

  blocTest<KmUpdateCubit, KmUpdateState>(
    'emette [loading, success] quando l\'aggiornamento riesce',
    build: () {
      when(
        () => updateVehicleKm(vehicleId: 'v1', newKm: 15000),
      ).thenAnswer((_) async => const Right(15000));
      return KmUpdateCubit(updateVehicleKm, addFuelExpense);
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
      return KmUpdateCubit(updateVehicleKm, addFuelExpense);
    },
    act: (cubit) => cubit.aggiorna(vehicleId: 'v1', newKm: 15000),
    expect: () => [
      const KmUpdateState(status: KmUpdateStatus.loading),
      isA<KmUpdateState>()
          .having((s) => s.status, 'status', KmUpdateStatus.failure)
          .having((s) => s.error, 'error', isNotNull),
    ],
  );

  blocTest<KmUpdateCubit, KmUpdateState>(
    'dopo i km registra il rifornimento quando i dati sono presenti',
    build: () {
      when(
        () => updateVehicleKm(vehicleId: 'v1', newKm: 15000),
      ).thenAnswer((_) async => const Right(15000));
      when(
        () => addFuelExpense(
          vehicleId: 'v1',
          expense: const FuelExpenseDraft(costCents: 5025, litersMilli: 32750),
        ),
      ).thenAnswer((_) async => const Right('fuel-1'));
      return KmUpdateCubit(updateVehicleKm, addFuelExpense);
    },
    act: (cubit) => cubit.aggiorna(
      vehicleId: 'v1',
      newKm: 15000,
      fuelExpense: const FuelExpenseDraft(costCents: 5025, litersMilli: 32750),
    ),
    expect: () => const [
      KmUpdateState(status: KmUpdateStatus.loading),
      KmUpdateState(status: KmUpdateStatus.success, savedKm: 15000),
    ],
    verify: (_) {
      verify(
        () => addFuelExpense(
          vehicleId: 'v1',
          expense: const FuelExpenseDraft(costCents: 5025, litersMilli: 32750),
        ),
      ).called(1);
    },
  );

  blocTest<KmUpdateCubit, KmUpdateState>(
    'non registra carburante quando i campi opzionali sono vuoti',
    build: () {
      when(
        () => updateVehicleKm(vehicleId: 'v1', newKm: 15000),
      ).thenAnswer((_) async => const Right(15000));
      return KmUpdateCubit(updateVehicleKm, addFuelExpense);
    },
    act: (cubit) => cubit.aggiorna(vehicleId: 'v1', newKm: 15000),
    expect: () => const [
      KmUpdateState(status: KmUpdateStatus.loading),
      KmUpdateState(status: KmUpdateStatus.success, savedKm: 15000),
    ],
    verify: (_) {
      verifyNever(
        () => addFuelExpense(
          vehicleId: any(named: 'vehicleId'),
          expense: any(named: 'expense'),
        ),
      );
    },
  );
}
