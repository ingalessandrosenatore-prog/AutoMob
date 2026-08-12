import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/disconnect_mechanic_cubit.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/disconnect_mechanic.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDisconnectMechanic extends Mock implements DisconnectMechanic {}

void main() {
  late MockDisconnectMechanic disconnectMechanic;

  setUp(() => disconnectMechanic = MockDisconnectMechanic());

  blocTest<DisconnectMechanicCubit, DisconnectMechanicState>(
    'emette loading e success quando scollega',
    setUp: () => when(
      () =>
          disconnectMechanic(vehicleId: 'vehicle-1', mechanicId: 'mechanic-1'),
    ).thenAnswer((_) async => const Right(null)),
    build: () => DisconnectMechanicCubit(disconnectMechanic),
    act: (cubit) =>
        cubit.submit(vehicleId: 'vehicle-1', mechanicId: 'mechanic-1'),
    expect: () => const [
      DisconnectMechanicState(status: DisconnectMechanicStatus.loading),
      DisconnectMechanicState(status: DisconnectMechanicStatus.success),
    ],
  );

  blocTest<DisconnectMechanicCubit, DisconnectMechanicState>(
    'emette loading e failure quando lo scollegamento fallisce',
    setUp: () => when(
      () =>
          disconnectMechanic(vehicleId: 'vehicle-1', mechanicId: 'mechanic-1'),
    ).thenAnswer((_) async => const Left(ServerFailure())),
    build: () => DisconnectMechanicCubit(disconnectMechanic),
    act: (cubit) =>
        cubit.submit(vehicleId: 'vehicle-1', mechanicId: 'mechanic-1'),
    expect: () => [
      const DisconnectMechanicState(status: DisconnectMechanicStatus.loading),
      DisconnectMechanicState(
        status: DisconnectMechanicStatus.failure,
        error: const ServerFailure().message,
      ),
    ],
  );
}
