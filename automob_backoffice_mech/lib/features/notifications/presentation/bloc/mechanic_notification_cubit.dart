import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/mechanic_notification.dart';
import '../../domain/usecases/send_mechanic_notification.dart';
import 'mechanic_notification_state.dart';

final class MechanicNotificationCubit extends Cubit<MechanicNotificationState> {
  MechanicNotificationCubit({
    required this.sendNotification,
    required this.vehicleId,
  }) : super(const MechanicNotificationState());
  final SendMechanicNotification sendNotification;
  final String vehicleId;
  String _requestId = const Uuid().v4();

  void selectType(MechanicNotificationType type) {
    if (state.sending || state.type == type) return;
    _requestId = const Uuid().v4();
    emit(state.copyWith(type: type, title: type.title, body: type.body));
  }

  void changeTitle(String title) {
    if (state.sending) return;
    _requestId = const Uuid().v4();
    emit(state.copyWith(title: title));
  }

  void changeBody(String body) {
    if (state.sending) return;
    _requestId = const Uuid().v4();
    emit(state.copyWith(body: body));
  }

  Future<void> send() async {
    if (!state.canSend) return;
    if (state.result == NotificationSendResult.failed ||
        state.result == NotificationSendResult.noDevice) {
      _requestId = const Uuid().v4();
    }
    // Preserve the key after a lost response: retry asks for the same send,
    // rather than delivering a second push to the customer.
    emit(state.copyWith(sending: true));
    final result = await sendNotification(
      MechanicNotification(
        vehicleId: vehicleId,
        requestId: _requestId,
        type: state.type,
        title: state.title,
        body: state.body,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(sending: false, error: failure.message)),
      (outcome) => emit(state.copyWith(sending: false, result: outcome)),
    );
  }
}
