import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/future_work_report.dart';
import '../../domain/entities/warning_light_observation.dart';
import '../../domain/usecases/create_future_work_report.dart';

enum FutureWorkReportStatus { editing, submitting, success, failure }

class FutureWorkReportState extends Equatable {
  const FutureWorkReportState({
    this.description = '',
    this.onboardMessage = '',
    this.warningLights = const [],
    this.reminderDate,
    this.status = FutureWorkReportStatus.editing,
    this.savedReport,
    this.error,
  });

  final String description;
  final String onboardMessage;
  final List<WarningLightObservation> warningLights;
  final DateTime? reminderDate;
  final FutureWorkReportStatus status;
  final FutureWorkReport? savedReport;
  final String? error;

  bool get canSubmit =>
      (description.trim().isNotEmpty ||
          onboardMessage.trim().isNotEmpty ||
          warningLights.isNotEmpty) &&
      reminderDate != null &&
      status != FutureWorkReportStatus.submitting;

  FutureWorkReportState copyWith({
    String? description,
    String? onboardMessage,
    List<WarningLightObservation>? warningLights,
    DateTime? reminderDate,
    FutureWorkReportStatus? status,
    FutureWorkReport? savedReport,
    String? error,
  }) => FutureWorkReportState(
    description: description ?? this.description,
    onboardMessage: onboardMessage ?? this.onboardMessage,
    warningLights: warningLights ?? this.warningLights,
    reminderDate: reminderDate ?? this.reminderDate,
    status: status ?? this.status,
    savedReport: savedReport,
    error: error,
  );

  @override
  List<Object?> get props => [
    description,
    onboardMessage,
    warningLights,
    reminderDate,
    status,
    savedReport,
    error,
  ];
}

class FutureWorkReportCubit extends Cubit<FutureWorkReportState> {
  FutureWorkReportCubit(this.createFutureWorkReport)
    : super(const FutureWorkReportState());

  final CreateFutureWorkReport createFutureWorkReport;

  void descriptionChanged(String value) {
    emit(
      state.copyWith(
        description: value,
        status: FutureWorkReportStatus.editing,
      ),
    );
  }

  void onboardMessageChanged(String value) => emit(
    state.copyWith(
      onboardMessage: value,
      status: FutureWorkReportStatus.editing,
    ),
  );

  void toggleWarning(
    String code, {
    String color = 'unknown',
    bool flashing = false,
  }) {
    final observation = WarningLightObservation(
      code: code,
      color: color,
      flashing: flashing,
    );
    final selected = state.warningLights.contains(observation);
    emit(
      state.copyWith(
        warningLights: List.unmodifiable(
          selected
              ? state.warningLights.where((light) => light != observation)
              : [...state.warningLights, observation],
        ),
        status: FutureWorkReportStatus.editing,
      ),
    );
  }

  void reminderDateChanged(DateTime value) {
    emit(
      state.copyWith(
        reminderDate: DateTime(value.year, value.month, value.day),
        status: FutureWorkReportStatus.editing,
      ),
    );
  }

  Future<void> submit(String vehicleId) async {
    if (state.status == FutureWorkReportStatus.submitting) return;
    final reminderDate = state.reminderDate;
    if (reminderDate == null) {
      emit(
        state.copyWith(
          status: FutureWorkReportStatus.failure,
          error: 'Seleziona la data entro cui effettuare il lavoro.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: FutureWorkReportStatus.submitting));
    final result = await createFutureWorkReport(
      vehicleId: vehicleId,
      description: state.description,
      onboardMessage: state.onboardMessage,
      warningLights: state.warningLights,
      reminderDate: reminderDate,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: FutureWorkReportStatus.failure,
          error: failure.message,
        ),
      ),
      (report) => emit(
        state.copyWith(
          status: FutureWorkReportStatus.success,
          savedReport: report,
        ),
      ),
    );
  }
}
