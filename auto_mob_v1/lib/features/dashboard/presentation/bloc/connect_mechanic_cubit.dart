import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../vehicle/domain/entities/mechanic_summary.dart';
import '../../../vehicle/domain/usecases/connect_mechanic.dart';

enum ConnectMechanicStatus { initial, loading, success, failure }

class ConnectMechanicState extends Equatable {
  final String code;
  final ConnectMechanicStatus status;
  final MechanicSummary? mechanic;
  final String? error;

  const ConnectMechanicState({
    this.code = '',
    this.status = ConnectMechanicStatus.initial,
    this.mechanic,
    this.error,
  });

  bool get canSubmit =>
      code.trim().isNotEmpty && status != ConnectMechanicStatus.loading;

  ConnectMechanicState copyWith({
    String? code,
    ConnectMechanicStatus? status,
    MechanicSummary? mechanic,
    String? error,
  }) {
    return ConnectMechanicState(
      code: code ?? this.code,
      status: status ?? this.status,
      mechanic: mechanic ?? this.mechanic,
      error: error,
    );
  }

  @override
  List<Object?> get props => [code, status, mechanic, error];
}

class ConnectMechanicCubit extends Cubit<ConnectMechanicState> {
  final ConnectMechanic connectMechanic;

  ConnectMechanicCubit(this.connectMechanic)
    : super(const ConnectMechanicState());

  void codeChanged(String code) {
    emit(state.copyWith(code: code, status: ConnectMechanicStatus.initial));
  }

  Future<void> submit({required String vehicleId}) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: ConnectMechanicStatus.loading));
    final result = await connectMechanic(
      vehicleId: vehicleId,
      mechanicCode: state.code,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ConnectMechanicStatus.failure,
          error: failure.message,
        ),
      ),
      (mechanic) => emit(
        state.copyWith(
          status: ConnectMechanicStatus.success,
          mechanic: mechanic,
        ),
      ),
    );
  }
}
