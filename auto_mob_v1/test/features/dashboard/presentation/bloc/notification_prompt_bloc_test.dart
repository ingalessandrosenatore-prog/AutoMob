import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/notification_prompt_bloc.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/notification_prompt_event.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/notification_prompt_state.dart';
import 'package:auto_mob_v1/features/notifications/domain/entities/notification_permission_status.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/postpone_notification_permission.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/register_device_token.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/request_notification_permission.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/should_offer_notification_permission.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockShouldOfferPermission extends Mock
    implements ShouldOfferNotificationPermission {}

class MockRequestPermission extends Mock
    implements RequestNotificationPermission {}

class MockPostponePermission extends Mock
    implements PostponeNotificationPermission {}

class MockRegisterDeviceToken extends Mock implements RegisterDeviceToken {}

void main() {
  late MockShouldOfferPermission shouldOffer;
  late MockRequestPermission requestPermission;
  late MockPostponePermission postponePermission;
  late MockRegisterDeviceToken registerDeviceToken;

  setUp(() {
    shouldOffer = MockShouldOfferPermission();
    requestPermission = MockRequestPermission();
    postponePermission = MockPostponePermission();
    registerDeviceToken = MockRegisterDeviceToken();
  });

  NotificationPromptBloc buildBloc() => NotificationPromptBloc(
    shouldOfferPermission: shouldOffer,
    requestPermission: requestPermission,
    postponePermission: postponePermission,
    registerDeviceToken: registerDeviceToken,
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'senza veicoli reali resta initial e non consulta il repository',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const NotificationPromptCheckRequested(hasRealVehicles: false),
    ),
    expect: () => <NotificationPromptState>[],
    verify: (_) => verifyNever(shouldOffer.call),
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'dopo un check senza veicoli puo rivalutare quando arriva la prima auto',
    build: () {
      when(shouldOffer.call).thenAnswer((_) async => const Right(true));
      return buildBloc();
    },
    act: (bloc) {
      bloc
        ..add(const NotificationPromptCheckRequested(hasRealVehicles: false))
        ..add(const NotificationPromptCheckRequested(hasRealVehicles: true));
    },
    expect: () => [
      const NotificationPromptChecking(),
      const NotificationPromptOfferRequired(),
    ],
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'con veicoli reali emette offerRequired quando il prompt va mostrato',
    build: () {
      when(shouldOffer.call).thenAnswer((_) async => const Right(true));
      return buildBloc();
    },
    act: (bloc) =>
        bloc.add(const NotificationPromptCheckRequested(hasRealVehicles: true)),
    expect: () => [
      const NotificationPromptChecking(),
      const NotificationPromptOfferRequired(),
    ],
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'Non ora salva il rinvio e conclude il workflow',
    build: () {
      when(postponePermission.call).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => const NotificationPromptOfferRequired(),
    act: (bloc) => bloc.add(const NotificationPromptPostponeRequested()),
    expect: () => [
      const NotificationPromptPostponing(),
      const NotificationPromptNotRequired(),
    ],
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'permesso autorizzato registra il token e termina enabled',
    build: () {
      when(requestPermission.call).thenAnswer(
        (_) async => const Right(NotificationPermissionStatus.authorized),
      );
      when(registerDeviceToken.call).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    seed: () => const NotificationPromptOfferRequired(),
    act: (bloc) => bloc.add(const NotificationPromptEnableRequested()),
    expect: () => [
      const NotificationPromptRequesting(),
      const NotificationPromptEnabled(),
    ],
    verify: (_) => verify(registerDeviceToken.call).called(1),
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'permesso negato non registra il token',
    build: () {
      when(requestPermission.call).thenAnswer(
        (_) async => const Right(NotificationPermissionStatus.denied),
      );
      return buildBloc();
    },
    seed: () => const NotificationPromptOfferRequired(),
    act: (bloc) => bloc.add(const NotificationPromptEnableRequested()),
    expect: () => [
      const NotificationPromptRequesting(),
      const NotificationPromptDenied(NotificationPermissionStatus.denied),
    ],
    verify: (_) => verifyNever(registerDeviceToken.call),
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'propaga una failure della registrazione come stato presentation',
    build: () {
      when(requestPermission.call).thenAnswer(
        (_) async => const Right(NotificationPermissionStatus.authorized),
      );
      when(
        registerDeviceToken.call,
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    seed: () => const NotificationPromptOfferRequired(),
    act: (bloc) => bloc.add(const NotificationPromptEnableRequested()),
    expect: () => [
      const NotificationPromptRequesting(),
      NotificationPromptFailure(const ServerFailure().message),
    ],
  );

  blocTest<NotificationPromptBloc, NotificationPromptState>(
    'un dialogo interrotto torna initial e puo essere rivalutato',
    build: () {
      when(shouldOffer.call).thenAnswer((_) async => const Right(true));
      return buildBloc();
    },
    seed: () => const NotificationPromptOfferRequired(),
    act: (bloc) {
      bloc
        ..add(const NotificationPromptOfferInterrupted())
        ..add(const NotificationPromptCheckRequested(hasRealVehicles: true));
    },
    expect: () => [
      const NotificationPromptInitial(),
      const NotificationPromptChecking(),
      const NotificationPromptOfferRequired(),
    ],
  );
}
