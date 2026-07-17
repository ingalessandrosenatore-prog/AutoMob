import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/revision_interval.dart';
import '../../domain/usecases/update_vehicle_revision.dart';

enum RevisionUpdateStatus { initial, loading, success, failure }

const _keepValue = Object();

class RevisionUpdateState extends Equatable {
  final RevisionUpdateStatus status;
  final DateTime? savedDate;
  final DateTime? selectedDate;
  final RevisionInterval? selectedInterval;
  final String? error;

  const RevisionUpdateState({
    this.status = RevisionUpdateStatus.initial,
    this.savedDate,
    this.selectedDate,
    this.selectedInterval,
    this.error,
  });

  RevisionUpdateState copyWith({
    RevisionUpdateStatus? status,
    Object? savedDate = _keepValue,
    Object? selectedDate = _keepValue,
    Object? selectedInterval = _keepValue,
    String? error,
  }) {
    return RevisionUpdateState(
      status: status ?? this.status,
      savedDate: identical(savedDate, _keepValue)
          ? this.savedDate
          : savedDate as DateTime?,
      selectedDate: identical(selectedDate, _keepValue)
          ? this.selectedDate
          : selectedDate as DateTime?,
      selectedInterval: identical(selectedInterval, _keepValue)
          ? this.selectedInterval
          : selectedInterval as RevisionInterval?,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    savedDate,
    selectedDate,
    selectedInterval,
    error,
  ];
}

class RevisionUpdateCubit extends Cubit<RevisionUpdateState> {
  final UpdateVehicleRevision updateVehicleRevision;

  RevisionUpdateCubit(this.updateVehicleRevision)
    : super(const RevisionUpdateState());

  void initialize(DateTime? currentDate) {
    if (currentDate == null) return;
    emit(
      state.copyWith(
        selectedDate: DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
        ),
      ),
    );
  }

  void selectInterval({
    required RevisionInterval interval,
    required DateTime from,
  }) {
    emit(
      state.copyWith(
        selectedInterval: interval,
        selectedDate: interval.dateFrom(from),
      ),
    );
  }

  void selectManualDate(DateTime date) {
    emit(
      state.copyWith(
        selectedInterval: null,
        selectedDate: DateTime(date.year, date.month, date.day),
      ),
    );
  }

  Future<void> aggiorna({required String vehicleId}) async {
    final nextRevisionDate = state.selectedDate;
    if (nextRevisionDate == null) return;
    emit(state.copyWith(status: RevisionUpdateStatus.loading, error: null));
    final result = await updateVehicleRevision(
      vehicleId: vehicleId,
      nextRevisionDate: nextRevisionDate,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RevisionUpdateStatus.failure,
          error: failure.message,
        ),
      ),
      (date) => emit(
        state.copyWith(status: RevisionUpdateStatus.success, savedDate: date),
      ),
    );
  }
}
