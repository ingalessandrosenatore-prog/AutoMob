import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/connect_mechanic_cubit.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/connect_mechanic.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectMechanic extends Mock implements ConnectMechanic {}

void main() {
  late MockConnectMechanic connectMechanic;

  const mechanic = MechanicSummary(
    id: 'mechanic-1',
    code: '482913',
    businessName: 'Officina Giordano',
  );

  setUp(() => connectMechanic = MockConnectMechanic());

  blocTest<ConnectMechanicCubit, ConnectMechanicState>(
    'aggiorna il codice inserito',
    build: () => ConnectMechanicCubit(connectMechanic),
    act: (cubit) => cubit.codeChanged('482913'),
    expect: () => const [ConnectMechanicState(code: '482913')],
  );

  blocTest<ConnectMechanicCubit, ConnectMechanicState>(
    'emette caricamento e successo quando il collegamento riesce',
    setUp: () {
      when(
        () => connectMechanic(vehicleId: 'vehicle-1', mechanicCode: '482913'),
      ).thenAnswer((_) async => const Right(mechanic));
    },
    build: () => ConnectMechanicCubit(connectMechanic),
    seed: () => const ConnectMechanicState(code: '482913'),
    act: (cubit) => cubit.submit(vehicleId: 'vehicle-1'),
    expect: () => const [
      ConnectMechanicState(
        code: '482913',
        status: ConnectMechanicStatus.loading,
      ),
      ConnectMechanicState(
        code: '482913',
        status: ConnectMechanicStatus.success,
        mechanic: mechanic,
      ),
    ],
  );

  blocTest<ConnectMechanicCubit, ConnectMechanicState>(
    'emette caricamento ed errore quando il collegamento fallisce',
    setUp: () {
      when(
        () => connectMechanic(vehicleId: 'vehicle-1', mechanicCode: '000000'),
      ).thenAnswer(
        (_) async =>
            const Left(ValidationFailure('Codice meccanico non valido.')),
      );
    },
    build: () => ConnectMechanicCubit(connectMechanic),
    seed: () => const ConnectMechanicState(code: '000000'),
    act: (cubit) => cubit.submit(vehicleId: 'vehicle-1'),
    expect: () => const [
      ConnectMechanicState(
        code: '000000',
        status: ConnectMechanicStatus.loading,
      ),
      ConnectMechanicState(
        code: '000000',
        status: ConnectMechanicStatus.failure,
        error: 'Codice meccanico non valido.',
      ),
    ],
  );
}
