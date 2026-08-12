import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/usecases/disconnect_mechanic.dart';

enum DisconnectMechanicStatus { initial, loading, success, failure }

class DisconnectMechanicState extends Equatable {
  final DisconnectMechanicStatus status;
  final String? error;

  const DisconnectMechanicState({
    this.status = DisconnectMechanicStatus.initial,
    this.error,
  });

  @override
  List<Object?> get props => [status, error];
}

class DisconnectMechanicCubit extends Cubit<DisconnectMechanicState> {
  final DisconnectMechanic disconnectMechanic;

  DisconnectMechanicCubit(this.disconnectMechanic)
    : super(const DisconnectMechanicState());

  Future<void> submit({
    required String vehicleId,
    required String mechanicId,
  }) async {
    if (state.status == DisconnectMechanicStatus.loading) return;
    emit(
      const DisconnectMechanicState(status: DisconnectMechanicStatus.loading),
    );

    final result = await disconnectMechanic(
      vehicleId: vehicleId,
      mechanicId: mechanicId,
    );
    result.fold(
      (failure) => emit(
        DisconnectMechanicState(
          status: DisconnectMechanicStatus.failure,
          error: failure.message,
        ),
      ),
      (_) => emit(
        const DisconnectMechanicState(status: DisconnectMechanicStatus.success),
      ),
    );
  }
}
