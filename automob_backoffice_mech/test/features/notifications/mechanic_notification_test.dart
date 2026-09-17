import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:automob_backoffice_mech/core/error/failure.dart';
import 'package:automob_backoffice_mech/features/notifications/domain/entities/mechanic_notification.dart';
import 'package:automob_backoffice_mech/features/notifications/domain/repositories/mechanic_notification_repository.dart';
import 'package:automob_backoffice_mech/features/notifications/domain/usecases/send_mechanic_notification.dart';
import 'package:automob_backoffice_mech/features/notifications/data/datasources/mechanic_notification_data_source.dart';
import 'package:automob_backoffice_mech/features/notifications/data/repositories/mechanic_notification_repository_impl.dart';
import 'package:automob_backoffice_mech/features/notifications/presentation/bloc/mechanic_notification_cubit.dart';

class FakeRepository implements MechanicNotificationRepository {
  final requests = <MechanicNotification>[];
  Future<Either<Failure, NotificationSendResult>> Function()? respond;
  @override
  Future<Either<Failure, NotificationSendResult>> send(
    MechanicNotification notification,
  ) {
    requests.add(notification);
    return respond?.call() ??
        Future.value(const Right(NotificationSendResult.sent));
  }
}

class FakeDataSource implements MechanicNotificationDataSource {
  bool fail = false;
  @override
  Future<NotificationSendResult> send(MechanicNotification notification) async {
    if (fail) throw StateError('network');
    return NotificationSendResult.noDevice;
  }
}

void main() {
  late FakeRepository repository;
  late MechanicNotificationCubit cubit;
  setUp(() {
    repository = FakeRepository();
    cubit = MechanicNotificationCubit(
      sendNotification: SendMechanicNotification(repository),
      vehicleId: 'vehicle',
    );
  });
  tearDown(() => cubit.close());

  test('each intervention sets an editable title and body', () {
    for (final type in MechanicNotificationType.values) {
      cubit.selectType(type);
      expect(cubit.state.title, type.title);
      expect(cubit.state.body, type.body);
      cubit.changeBody('Testo personalizzato');
      cubit.selectType(type);
      expect(cubit.state.body, 'Testo personalizzato');
    }
  });
  test(
    'send carries selected vehicle, intervention and trimmed edited text',
    () async {
      cubit.selectType(MechanicNotificationType.tireChange);
      cubit.changeTitle('  Gomme nuove  ');
      cubit.changeBody(' Vieni lunedì ');
      await cubit.send();
      final request = repository.requests.single;
      expect(request.vehicleId, 'vehicle');
      expect(request.type, MechanicNotificationType.tireChange);
      expect(request.title, 'Gomme nuove');
      expect(request.body, 'Vieni lunedì');
      expect(cubit.state.result, NotificationSendResult.sent);
    },
  );
  test('empty and oversized inputs never reach repository', () async {
    cubit.changeTitle(' ');
    await cubit.send();
    cubit.changeTitle('x' * 101);
    await cubit.send();
    expect(repository.requests, isEmpty);
    expect(cubit.state.error, isNotNull);
  });
  test('double tap sends once and blocks edits during request', () async {
    final completion = Completer<Either<Failure, NotificationSendResult>>();
    repository.respond = () => completion.future;
    final send = cubit.send();
    await cubit.send();
    cubit.selectType(MechanicNotificationType.service);
    expect(cubit.state.type, MechanicNotificationType.distribution);
    expect(repository.requests, hasLength(1));
    completion.complete(const Right(NotificationSendResult.sent));
    await send;
    await cubit.send();
    expect(repository.requests, hasLength(1));
  });
  test(
    'uncertain response retries same key; definitive failure permits new attempt',
    () async {
      repository.respond = () async => const Left(ServerFailure());
      await cubit.send();
      await cubit.send();
      expect(
        repository.requests[0].requestId,
        repository.requests[1].requestId,
      );
      repository.respond = () async =>
          const Right(NotificationSendResult.noDevice);
      await cubit.send();
      await cubit.send();
      expect(
        repository.requests[2].requestId,
        isNot(repository.requests[3].requestId),
      );
    },
  );
  test(
    'repository preserves no-device outcome and converts exceptions',
    () async {
      final source = FakeDataSource();
      final repository = MechanicNotificationRepositoryImpl(source);
      const draft = MechanicNotification(
        vehicleId: 'vehicle',
        requestId: 'request',
        type: MechanicNotificationType.service,
        title: 'Titolo',
        body: 'Messaggio',
      );
      expect(
        (await repository.send(
          draft,
        )).getOrElse((_) => NotificationSendResult.failed),
        NotificationSendResult.noDevice,
      );
      source.fail = true;
      expect((await repository.send(draft)).isLeft(), isTrue);
    },
  );
}
