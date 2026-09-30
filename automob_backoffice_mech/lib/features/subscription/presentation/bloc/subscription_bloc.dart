import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_subscription_overview.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

final class SubscriptionBloc
    extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc({required this.getSubscriptionOverview})
    : super(const SubscriptionInitial()) {
    on<SubscriptionStarted>(_onStarted);
    on<SubscriptionRetryRequested>(_onRetryRequested);
  }

  final GetSubscriptionOverview getSubscriptionOverview;

  Future<void> _onStarted(
    SubscriptionStarted event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (state is! SubscriptionInitial) return;
    await _load(emit);
  }

  Future<void> _onRetryRequested(
    SubscriptionRetryRequested event,
    Emitter<SubscriptionState> emit,
  ) => _load(emit);

  Future<void> _load(Emitter<SubscriptionState> emit) async {
    emit(const SubscriptionLoading());
    final result = await getSubscriptionOverview();
    result.match(
      (failure) => emit(SubscriptionLoadFailure(failure.message)),
      (overview) => emit(SubscriptionReady(overview)),
    );
  }
}
