import 'package:auto_mob_v1/features/notifications/domain/entities/notification_permission_status.dart';
import 'package:auto_mob_v1/features/notifications/domain/entities/notification_message.dart';
import 'package:auto_mob_v1/features/notifications/domain/repositories/notification_repository.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/observe_notification_messages.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/postpone_notification_permission.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/register_device_token.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/request_notification_permission.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/should_offer_notification_permission.dart';
import 'package:auto_mob_v1/features/notifications/domain/usecases/unregister_device_token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late _MockNotificationRepository repository;

  setUp(() => repository = _MockNotificationRepository());

  test('ShouldOfferNotificationPermission delega al repository', () async {
    when(
      repository.shouldOfferPermission,
    ).thenAnswer((_) async => const Right(true));

    final result = await ShouldOfferNotificationPermission(repository)();

    expect(result, const Right(true));
    verify(repository.shouldOfferPermission).called(1);
  });

  test('RequestNotificationPermission restituisce lo stato', () async {
    when(repository.requestPermission).thenAnswer(
      (_) async => const Right(NotificationPermissionStatus.authorized),
    );

    final result = await RequestNotificationPermission(repository)();

    expect(result, const Right(NotificationPermissionStatus.authorized));
  });

  test('RegisterDeviceToken registra il dispositivo corrente', () async {
    when(
      repository.registerCurrentDevice,
    ).thenAnswer((_) async => const Right(null));

    await RegisterDeviceToken(repository)();

    verify(repository.registerCurrentDevice).called(1);
  });

  test('UnregisterDeviceToken disattiva il dispositivo corrente', () async {
    when(
      repository.unregisterCurrentDevice,
    ).thenAnswer((_) async => const Right(null));

    await UnregisterDeviceToken(repository)();

    verify(repository.unregisterCurrentDevice).called(1);
  });

  test('PostponeNotificationPermission rinvia il prompt', () async {
    when(
      repository.postponePermissionPrompt,
    ).thenAnswer((_) async => const Right(null));

    await PostponeNotificationPermission(repository)();

    verify(repository.postponePermissionPrompt).called(1);
  });

  test('ObserveNotificationMessages espone gli stream del repository', () {
    const message = NotificationMessage(data: {'type': 'km'});
    when(() => repository.messagingAvailable).thenReturn(true);
    when(
      () => repository.tokenRefreshes,
    ).thenAnswer((_) => const Stream<void>.empty());
    when(
      () => repository.foregroundMessages,
    ).thenAnswer((_) => Stream.value(message));
    when(
      () => repository.openedMessages,
    ).thenAnswer((_) => const Stream<NotificationMessage>.empty());

    final usecase = ObserveNotificationMessages(repository);

    expect(usecase.isAvailable, isTrue);
    expect(usecase.foregroundMessages, emits(message));
  });
}
