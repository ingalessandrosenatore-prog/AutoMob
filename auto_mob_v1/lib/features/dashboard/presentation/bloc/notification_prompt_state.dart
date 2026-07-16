import 'package:equatable/equatable.dart';

import '../../../notifications/domain/entities/notification_permission_status.dart';

sealed class NotificationPromptState extends Equatable {
  const NotificationPromptState();

  @override
  List<Object?> get props => [];
}

final class NotificationPromptInitial extends NotificationPromptState {
  const NotificationPromptInitial();
}

final class NotificationPromptChecking extends NotificationPromptState {
  const NotificationPromptChecking();
}

final class NotificationPromptNotRequired extends NotificationPromptState {
  const NotificationPromptNotRequired();
}

final class NotificationPromptOfferRequired extends NotificationPromptState {
  const NotificationPromptOfferRequired();
}

final class NotificationPromptPostponing extends NotificationPromptState {
  const NotificationPromptPostponing();
}

final class NotificationPromptRequesting extends NotificationPromptState {
  const NotificationPromptRequesting();
}

final class NotificationPromptEnabled extends NotificationPromptState {
  const NotificationPromptEnabled();
}

final class NotificationPromptDenied extends NotificationPromptState {
  const NotificationPromptDenied(this.status);

  final NotificationPermissionStatus status;

  @override
  List<Object?> get props => [status];
}

final class NotificationPromptFailure extends NotificationPromptState {
  const NotificationPromptFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
