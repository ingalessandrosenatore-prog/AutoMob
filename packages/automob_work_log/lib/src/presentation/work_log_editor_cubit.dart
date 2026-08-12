import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/work_log_draft.dart';
import '../domain/work_log_launch_context.dart';
import '../domain/work_log_use_cases.dart';

enum WorkLogEditorStatus { editing, saving, success, failure }

const _unset = Object();

class WorkLogEditorState extends Equatable {
  const WorkLogEditorState({
    this.vehicleId = '',
    this.minimumKm = 0,
    this.step = 0,
    this.type = 'altro',
    this.customName = '',
    this.serviceKm = 0,
    required this.serviceDate,
    this.notes = '',
    this.intervalKm,
    this.parts = const [],
    this.partsQuery = '',
    this.status = WorkLogEditorStatus.editing,
    this.message,
    this.result,
  });

  factory WorkLogEditorState.initial() =>
      WorkLogEditorState(serviceDate: DateTime.now());

  final String vehicleId;
  final int minimumKm;
  final int step;
  final String type;
  final String customName;
  final int serviceKm;
  final DateTime serviceDate;
  final String notes;
  final int? intervalKm;
  final List<WorkLogPartDraft> parts;
  final String partsQuery;
  final WorkLogEditorStatus status;
  final String? message;
  final WorkLogSaveResult? result;

  double get partsTotal =>
      parts.fold(0, (total, part) => total + part.subtotal);
  bool get isSaving => status == WorkLogEditorStatus.saving;

  WorkLogEditorState copyWith({
    String? vehicleId,
    int? minimumKm,
    int? step,
    String? type,
    String? customName,
    int? serviceKm,
    DateTime? serviceDate,
    String? notes,
    Object? intervalKm = _unset,
    List<WorkLogPartDraft>? parts,
    String? partsQuery,
    WorkLogEditorStatus? status,
    Object? message = _unset,
    Object? result = _unset,
  }) => WorkLogEditorState(
    vehicleId: vehicleId ?? this.vehicleId,
    minimumKm: minimumKm ?? this.minimumKm,
    step: step ?? this.step,
    type: type ?? this.type,
    customName: customName ?? this.customName,
    serviceKm: serviceKm ?? this.serviceKm,
    serviceDate: serviceDate ?? this.serviceDate,
    notes: notes ?? this.notes,
    intervalKm: identical(intervalKm, _unset)
        ? this.intervalKm
        : intervalKm as int?,
    parts: parts ?? this.parts,
    partsQuery: partsQuery ?? this.partsQuery,
    status: status ?? this.status,
    message: identical(message, _unset) ? this.message : message as String?,
    result: identical(result, _unset)
        ? this.result
        : result as WorkLogSaveResult?,
  );

  @override
  List<Object?> get props => [
    vehicleId,
    minimumKm,
    step,
    type,
    customName,
    serviceKm,
    serviceDate,
    notes,
    intervalKm,
    parts,
    partsQuery,
    status,
    message,
    result,
  ];
}

class WorkLogEditorCubit extends Cubit<WorkLogEditorState> {
  WorkLogEditorCubit({required this.createWorkLog})
    : super(WorkLogEditorState.initial());

  final CreateWorkLog createWorkLog;

  void initialize(WorkLogLaunchContext context) => emit(
    WorkLogEditorState(
      vehicleId: context.vehicleId,
      minimumKm: context.currentKm,
      type: context.initialWorkType,
      serviceKm: context.currentKm,
      serviceDate: DateTime.now(),
    ),
  );

  void changeStep(int step) => emit(state.copyWith(step: step.clamp(0, 2)));
  void previousStep() => changeStep(state.step - 1);

  void resumeEditing() =>
      emit(state.copyWith(status: WorkLogEditorStatus.editing, message: null));

  void nextStep() {
    if (state.step == 0) {
      final validation = validateData();
      if (validation != null) {
        emit(
          state.copyWith(
            status: WorkLogEditorStatus.failure,
            message: validation,
          ),
        );
        return;
      }
    }
    changeStep(state.step + 1);
  }

  void changeType(String value) => emit(
    state.copyWith(
      type: value,
      status: WorkLogEditorStatus.editing,
      message: null,
    ),
  );
  void changeCustomName(String value) =>
      emit(state.copyWith(customName: value, message: null));
  void changeKm(String value) =>
      emit(state.copyWith(serviceKm: int.tryParse(value) ?? 0, message: null));
  void changeDate(DateTime value) => emit(state.copyWith(serviceDate: value));
  void changeNotes(String value) => emit(state.copyWith(notes: value));
  void changeInterval(String value) =>
      emit(state.copyWith(intervalKm: int.tryParse(value)));
  void changePartsQuery(String value) =>
      emit(state.copyWith(partsQuery: value));

  void togglePart(int partId) {
    final selected = state.parts.any((part) => part.partId == partId);
    emit(
      state.copyWith(
        parts: selected
            ? state.parts.where((part) => part.partId != partId).toList()
            : [...state.parts, WorkLogPartDraft(partId: partId)],
      ),
    );
  }

  void updatePart(WorkLogPartDraft updated) => emit(
    state.copyWith(
      parts: state.parts
          .map((part) => part.partId == updated.partId ? updated : part)
          .toList(growable: false),
    ),
  );

  void removePart(int partId) => emit(
    state.copyWith(
      parts: state.parts.where((part) => part.partId != partId).toList(),
    ),
  );

  String? validateData() {
    if (state.serviceKm < state.minimumKm) {
      return 'Inserisci almeno ${state.minimumKm} km.';
    }
    if (state.type == 'altro' && state.customName.trim().isEmpty) {
      return 'Specifica il tipo di intervento.';
    }
    if (state.serviceDate.isAfter(DateTime.now())) {
      return 'La data del lavoro non può essere futura.';
    }
    return null;
  }

  Future<void> submit() async {
    if (state.isSaving) return;
    final validation = validateData();
    if (validation != null) {
      emit(
        state.copyWith(
          status: WorkLogEditorStatus.failure,
          message: validation,
        ),
      );
      return;
    }

    emit(state.copyWith(status: WorkLogEditorStatus.saving, message: null));
    final draft = WorkLogDraft(
      vehicleId: state.vehicleId,
      type: state.type,
      customName: state.customName.trim().isEmpty
          ? null
          : state.customName.trim(),
      serviceKm: state.serviceKm,
      serviceDate: state.serviceDate,
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      intervalKm: state.intervalKm,
      parts: state.parts,
    );
    final response = await createWorkLog(draft);
    response.fold(
      (message) => emit(
        state.copyWith(status: WorkLogEditorStatus.failure, message: message),
      ),
      (_) => emit(
        state.copyWith(
          status: WorkLogEditorStatus.success,
          result: WorkLogSaveResult(
            vehicleId: state.vehicleId,
            serviceKm: state.serviceKm,
          ),
        ),
      ),
    );
  }
}
