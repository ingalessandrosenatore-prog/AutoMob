import 'package:equatable/equatable.dart';

sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => const [];
}

final class SubscriptionStarted extends SubscriptionEvent {
  const SubscriptionStarted();
}

final class SubscriptionRetryRequested extends SubscriptionEvent {
  const SubscriptionRetryRequested();
}
