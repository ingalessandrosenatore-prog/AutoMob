import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/work_log_draft.dart';
import '../domain/work_log_launch_context.dart';
import '../domain/work_log_parts_catalog.dart';
import '../domain/work_log_parts_data.dart';
import '../domain/work_log_report.dart';
import '../domain/work_log_type.dart';
import '../domain/work_log_use_cases.dart';
import 'work_log_report_notes.dart';

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
    this.openReports = const [],
    this.selectedReportIds = const {},
    this.loadingReports = false,
    this.loadingParts = false,
    this.partsError,
    this.partsData,
    this.reportsError,
    this.intervalKm,
    this.parts = const [],
    this.partsQuery = '',
    this.partsCategory,
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
  final List<WorkLogReport> openReports;
  final Set<String> selectedReportIds;
  final bool loadingReports;
  final bool loadingParts;
  final String? partsError;
  final WorkLogPartsData? partsData;
  final String? reportsError;
  final int? intervalKm;
  final List<WorkLogPartDraft> parts;
  final String partsQuery;
  final WorkLogPartCategory? partsCategory;
  final WorkLogEditorStatus status;
  final String? message;
  final WorkLogSaveResult? result;

  double get partsTotal =>
      parts.fold(0, (total, part) => total + part.subtotal);
  bool get isSaving => status == WorkLogEditorStatus.saving;
  bool get canSave =>
      status == WorkLogEditorStatus.editing &&
      !loadingParts &&
      partsError == null &&
      !loadingReports &&
      (reportsError == null || selectedReportIds.isEmpty);

  Iterable<WorkLogReport> get selectedReports =>
      openReports.where((report) => selectedReportIds.contains(report.id));

  String get composedNotes =>
      appendResolvedProblemsNotes(notes.trim(), resolvedProblemsNotes);
  String get resolvedProblemsNotes =>
      composeResolvedProblemsNotes(selectedReports);

  WorkLogEditorState copyWith({
    String? vehicleId,
    int? minimumKm,
    int? step,
    String? type,
    String? customName,
    int? serviceKm,
    DateTime? serviceDate,
    String? notes,
    List<WorkLogReport>? openReports,
    Set<String>? selectedReportIds,
    bool? loadingReports,
    bool? loadingParts,
    Object? partsError = _unset,
    WorkLogPartsData? partsData,
    Object? reportsError = _unset,
    Object? intervalKm = _unset,
    List<WorkLogPartDraft>? parts,
    String? partsQuery,
    Object? partsCategory = _unset,
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
    openReports: openReports ?? this.openReports,
    selectedReportIds: selectedReportIds ?? this.selectedReportIds,
    loadingReports: loadingReports ?? this.loadingReports,
    loadingParts: loadingParts ?? this.loadingParts,
    partsError: identical(partsError, _unset)
        ? this.partsError
        : partsError as String?,
    partsData: partsData ?? this.partsData,
    reportsError: identical(reportsError, _unset)
        ? this.reportsError
        : reportsError as String?,
    intervalKm: identical(intervalKm, _unset)
        ? this.intervalKm
        : intervalKm as int?,
    parts: parts ?? this.parts,
    partsQuery: partsQuery ?? this.partsQuery,
    partsCategory: identical(partsCategory, _unset)
        ? this.partsCategory
        : partsCategory as WorkLogPartCategory?,
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
    openReports,
    selectedReportIds,
    loadingReports,
    loadingParts,
    partsError,
    partsData,
    reportsError,
    intervalKm,
    parts,
    partsQuery,
    partsCategory,
    status,
    message,
    result,
  ];
}

class WorkLogEditorCubit extends Cubit<WorkLogEditorState> {
  WorkLogEditorCubit({
    required this.createWorkLog,
    required this.getOpenReports,
    this.getPartsData,
  }) : super(WorkLogEditorState.initial());

  final CreateWorkLog createWorkLog;
  final GetOpenWorkLogReports getOpenReports;
  final GetWorkLogPartsData? getPartsData;
  final _editedSelections = <String, List<WorkLogPartDraft>>{};
  int _partsRequest = 0;

  void initialize(WorkLogLaunchContext context) {
    _editedSelections.clear();
    emit(
      WorkLogEditorState(
        vehicleId: context.vehicleId,
        minimumKm: context.currentKm,
        type: context.initialWorkType,
        customName: context.initialCustomName,
        notes: context.initialNotes,
        selectedReportIds: {?context.sourceReportId},
        partsCategory: workLogPartCategoryForType(
          WorkLogType.tryFromWire(context.initialWorkType),
        ),
        serviceKm: context.currentKm,
        serviceDate: DateTime.now(),
      ),
    );
    unawaited(loadReports());
    unawaited(loadParts());
  }

  Future<void> loadParts() async {
    final load = getPartsData;
    if (load == null || state.isSaving) return;
    final request = ++_partsRequest;
    emit(state.copyWith(loadingParts: true, partsError: null));
    final result = await load(state.vehicleId);
    if (isClosed || request != _partsRequest) return;
    result.fold(
      (message) =>
          emit(state.copyWith(loadingParts: false, partsError: message)),
      (data) => emit(
        state.copyWith(
          loadingParts: false,
          partsData: data,
          parts: _selectionFor(state.type, data),
        ),
      ),
    );
  }

  List<WorkLogPartDraft> _selectionFor(String type, WorkLogPartsData? data) =>
      _editedSelections[type] ??
      [
        for (final id in data?.presets[type] ?? const <int>[])
          WorkLogPartDraft(partId: id, quantity: 1),
      ];

  Future<void> loadReports() async {
    if (state.loadingReports || state.isSaving) return;
    final vehicleId = state.vehicleId;
    emit(state.copyWith(loadingReports: true, reportsError: null));
    final response = await getOpenReports(vehicleId);
    if (isClosed || state.vehicleId != vehicleId) return;
    response.fold(
      (message) =>
          emit(state.copyWith(loadingReports: false, reportsError: message)),
      (reports) => emit(
        state.copyWith(
          openReports: List.unmodifiable(reports),
          selectedReportIds: Set.unmodifiable({
            for (final report in reports)
              if (state.selectedReportIds.contains(report.id)) report.id,
          }),
          loadingReports: false,
        ),
      ),
    );
  }

  void selectReport(String id, bool selected) {
    if (state.isSaving ||
        state.loadingReports ||
        !state.openReports.any((report) => report.id == id)) {
      return;
    }
    final ids = {...state.selectedReportIds};
    if (selected) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    emit(state.copyWith(selectedReportIds: Set.unmodifiable(ids)));
  }

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

  void changeType(String value) {
    final type = WorkLogType.tryFromWire(value);
    emit(
      state.copyWith(
        type: value,
        parts: value == state.type
            ? state.parts
            : _selectionFor(value, state.partsData),
        partsCategory: workLogPartCategoryForType(type),
        customName: type?.allowsCustomName == true ? state.customName : '',
        status: WorkLogEditorStatus.editing,
        message: null,
      ),
    );
  }

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

  void changePartsCategory(WorkLogPartCategory category) => emit(
    state.copyWith(
      partsCategory: state.partsCategory == category ? null : category,
    ),
  );

  void togglePart(int partId) {
    final selected = state.parts.any((part) => part.partId == partId);
    _updateSelection(
      selected
          ? state.parts.where((part) => part.partId != partId).toList()
          : [...state.parts, WorkLogPartDraft(partId: partId)],
    );
  }

  void updatePart(WorkLogPartDraft updated) => _updateSelection(
    state.parts
        .map((part) => part.partId == updated.partId ? updated : part)
        .toList(growable: false),
  );

  void removePart(int partId) => _updateSelection(
    state.parts.where((part) => part.partId != partId).toList(),
  );

  void _updateSelection(List<WorkLogPartDraft> parts) {
    _editedSelections[state.type] = List.unmodifiable(parts);
    emit(state.copyWith(parts: _editedSelections[state.type]));
  }

  String? validateData() {
    if (state.serviceKm < state.minimumKm) {
      return 'Inserisci almeno ${state.minimumKm} km.';
    }
    final workType = WorkLogType.tryFromWire(state.type);
    if (workType?.requiresCustomName == true &&
        state.customName.trim().isEmpty) {
      return 'Specifica il tipo di intervento.';
    }
    if (state.serviceDate.isAfter(DateTime.now())) {
      return 'La data del lavoro non può essere futura.';
    }
    return null;
  }

  Future<void> submit() async {
    if (!state.canSave) return;
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
    final workType = WorkLogType.tryFromWire(state.type);
    final notes = state.composedNotes;
    final draft = WorkLogDraft(
      vehicleId: state.vehicleId,
      resolvedReportIds: state.selectedReports
          .map((report) => report.id)
          .toList(growable: false),
      type: state.type,
      customName:
          workType?.allowsCustomName == true &&
              state.customName.trim().isNotEmpty
          ? state.customName.trim()
          : null,
      serviceKm: state.serviceKm,
      serviceDate: state.serviceDate,
      notes: notes.isEmpty ? null : notes,
      intervalKm: state.intervalKm,
      parts: state.parts,
    );
    final response = await createWorkLog(draft);
    if (isClosed) return;
    response.fold(
      (message) {
        emit(
          state.copyWith(status: WorkLogEditorStatus.failure, message: message),
        );
        if (draft.resolvedReportIds.isNotEmpty) unawaited(loadReports());
      },
      (_) => emit(
        state.copyWith(
          status: WorkLogEditorStatus.success,
          result: WorkLogSaveResult(
            vehicleId: state.vehicleId,
            serviceKm: state.serviceKm,
            resolvedReportIds: draft.resolvedReportIds,
          ),
        ),
      ),
    );
  }
}
