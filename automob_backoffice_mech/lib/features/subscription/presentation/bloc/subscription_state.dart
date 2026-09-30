import 'package:equatable/equatable.dart';

import '../../domain/entities/subscription_overview.dart';

sealed class SubscriptionState extends Equatable {
  const SubscriptionState();
}

final class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();

  @override
  List<Object?> get props => const [];
}

final class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();

  @override
  List<Object?> get props => const [];
}

final class SubscriptionReady extends SubscriptionState {
  const SubscriptionReady(this.overview);

  final SubscriptionOverview overview;

  @override
  List<Object?> get props => [overview];
}

final class SubscriptionLoadFailure extends SubscriptionState {
  const SubscriptionLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
