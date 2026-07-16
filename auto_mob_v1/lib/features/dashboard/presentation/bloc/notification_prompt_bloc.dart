import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notifications/domain/usecases/postpone_notification_permission.dart';
import '../../../notifications/domain/usecases/register_device_token.dart';
import '../../../notifications/domain/usecases/request_notification_permission.dart';
import '../../../notifications/domain/usecases/should_offer_notification_permission.dart';
import 'notification_prompt_event.dart';
import 'notification_prompt_state.dart';

/// Coordina il workflow notifiche avviato dalla dashboard.
///
/// Vive nella presentation della dashboard per rispettare la regola del
/// progetto che vieta comunicazioni e import tra BLoC di feature diverse.
/// Dipende esclusivamente dall'API pubblica `notifications/domain`.
class NotificationPromptBloc
    extends Bloc<NotificationPromptEvent, NotificationPromptState> {
  NotificationPromptBloc({
    required this.shouldOfferPermission,
    required this.requestPermission,
    required this.postponePermission,
    required this.registerDeviceToken,
  }) : super(const NotificationPromptInitial()) {
    on<NotificationPromptCheckRequested>(_onCheckRequested);
    on<NotificationPromptPostponeRequested>(_onPostponeRequested);
    on<NotificationPromptEnableRequested>(_onEnableRequested);
    on<NotificationPromptOfferInterrupted>(_onOfferInterrupted);
  }

  final ShouldOfferNotificationPermission shouldOfferPermission;
  final RequestNotificationPermission requestPermission;
  final PostponeNotificationPermission postponePermission;
  final RegisterDeviceToken registerDeviceToken;

  Future<void> _onCheckRequested(
    NotificationPromptCheckRequested event,
    Emitter<NotificationPromptState> emit,
  ) async {
    // Una singola istanza controlla il prompt una volta sola. Se HomeView viene
    // ricreata, la factory DI fornisce un nuovo BLoC che rilegge lo stato reale
    // da Firebase e SharedPreferences.
    if (state is! NotificationPromptInitial) return;
    // Restiamo Initial: quando l'utente registra il primo veicolo la dashboard
    // inviera' un nuovo check sulla stessa istanza.
    if (!event.hasRealVehicles) return;

    emit(const NotificationPromptChecking());
    final result = await shouldOfferPermission();
    result.fold(
      (failure) => emit(NotificationPromptFailure(failure.message)),
      (shouldOffer) => emit(
        shouldOffer
            ? const NotificationPromptOfferRequired()
            : const NotificationPromptNotRequired(),
      ),
    );
  }

  Future<void> _onPostponeRequested(
    NotificationPromptPostponeRequested event,
    Emitter<NotificationPromptState> emit,
  ) async {
    if (state is! NotificationPromptOfferRequired) return;

    emit(const NotificationPromptPostponing());
    final result = await postponePermission();
    result.fold(
      (failure) => emit(NotificationPromptFailure(failure.message)),
      (_) => emit(const NotificationPromptNotRequired()),
    );
  }

  Future<void> _onEnableRequested(
    NotificationPromptEnableRequested event,
    Emitter<NotificationPromptState> emit,
  ) async {
    if (state is! NotificationPromptOfferRequired) return;

    emit(const NotificationPromptRequesting());
    final permissionResult = await requestPermission();
    await permissionResult.fold(
      (failure) async => emit(NotificationPromptFailure(failure.message)),
      (status) async {
        if (!status.canReceiveNotifications) {
          emit(NotificationPromptDenied(status));
          return;
        }

        final registrationResult = await registerDeviceToken();
        registrationResult.fold(
          (failure) => emit(NotificationPromptFailure(failure.message)),
          (_) => emit(const NotificationPromptEnabled()),
        );
      },
    );
  }

  void _onOfferInterrupted(
    NotificationPromptOfferInterrupted event,
    Emitter<NotificationPromptState> emit,
  ) {
    if (state is NotificationPromptOfferRequired) {
      emit(const NotificationPromptInitial());
    }
  }
}
