import 'dart:async';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/create_work_log.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkLogBloc extends Bloc<WorkLogEvent, WorkLogState> {
  final CreateWorkLog createWorkLog;
  final String vehicleId;

  WorkLogBloc({required this.createWorkLog, required this.vehicleId})
    : super(WorkLogState.initial()) {
    on<WorkLogEventCohiceTap>(_onTapOnChoice);
    on<OnSubmitEvent>(_onSubmitEvent);
    on<InitKm>(_onInitKm);
    on<CurrentKmChange>(_onKmChange);
    on<RichiamoChange>(_onRichiamoChange);
    on<OnWorkTypeChange>(_onWorkTypeChange);
    on<CustomNameChange>(_onCustomNameChange);
    on<NoteChange>(_onNoteChange);
    on<ServiceDateChange>(_onServiceDateChange);
    on<RemovePartEvent>(_onRemovePart);
    on<UpdatePartItemEvent>(_onUpdatePartItem);
    on<WorkLogWizardStepChanged>(_onWizardStepChanged);
    on<PartsQueryChanged>(_onPartsQueryChanged);
    on<WorkLogValidationRequested>(_onValidationRequested);
  }

  FutureOr<void> _onTapOnChoice(
    WorkLogEventCohiceTap event,
    Emitter<WorkLogState> emit,
  ) {
    final current = List<SelectedPart>.from(state.selectedParts);
    final alreadySelected = current.any((item) => item.partId == event.id);
    if (alreadySelected) {
      current.removeWhere((item) => item.partId == event.id);
    } else {
      current.add(SelectedPart(partId: event.id, quantity: 1));
    }
    emit(state.copyWith(selectedParts: current));
  }

  Future<void> _onSubmitEvent(
    OnSubmitEvent event,
    Emitter<WorkLogState> emit,
  ) async {
    final isAltro = state.type == EnumPopUp.altro;
    final customNameTrimmed = state.customName?.trim() ?? '';
    if (isAltro && customNameTrimmed.isEmpty) {
      emit(
        state.copyWith(
          status: WorkLogStatus.failure,
          errorMessage: 'Inserisci un nome per l\'intervento "Altro"',
          errorCode: 'validation_error',
        ),
      );
      return;
    }

    // I km del lavoro non possono essere inferiori ai km attuali del veicolo.
    if (state.currentKm < state.vehicleKm) {
      emit(
        state.copyWith(
          status: WorkLogStatus.failure,
          errorMessage:
              'I km del lavoro non possono essere inferiori agli attuali (${state.vehicleKm} km)',
          errorCode: 'validation_error',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: WorkLogStatus.loading,
        errorMessage: null,
        errorCode: null,
      ),
    );
    final res = await createWorkLog(
      vehicleId: vehicleId,
      type: state.type.dbValue,
      customName: isAltro ? customNameTrimmed : null,
      serviceKm: state.currentKm,
      serviceDate: state.serviceDate,
      notes: state.note.isEmpty ? null : state.note,
      intervallKm: state.intervallKM,
      items: state.selectedParts,
    );
    res.fold(
      (f) => emit(
        state.copyWith(
          status: WorkLogStatus.failure,
          errorMessage: f.message,
          errorCode: f is CodedServerFailure ? f.code : 'network_error',
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: WorkLogStatus.success,
          errorMessage: null,
          errorCode: null,
        ),
      ),
    );
  }

  FutureOr<void> _onInitKm(InitKm event, Emitter<WorkLogState> emit) {
    emit(
      state.copyWith(
        vehicleKm: event.vehicleKm,
        currentKm: event.vehicleKm,
        prosssimoRichiamo: event.vehicleKm + state.intervallKM,
      ),
    );
  }

  FutureOr<void> _onKmChange(
    CurrentKmChange event,
    Emitter<WorkLogState> emit,
  ) {
    emit(
      state.copyWith(
        currentKm: event.currentKm,
        prosssimoRichiamo: event.currentKm + state.intervallKM,
      ),
    );
  }

  FutureOr<void> _onRichiamoChange(
    RichiamoChange event,
    Emitter<WorkLogState> emit,
  ) {
    emit(
      state.copyWith(
        prosssimoRichiamo: state.currentKm + event.intervallKM,
        intervallKM: event.intervallKM,
      ),
    );
  }

  FutureOr<void> _onWorkTypeChange(
    OnWorkTypeChange event,
    Emitter<WorkLogState> emit,
  ) {
    emit(state.copyWith(type: event.type));
  }

  FutureOr<void> _onCustomNameChange(
    CustomNameChange event,
    Emitter<WorkLogState> emit,
  ) {
    emit(state.copyWith(customName: event.customName));
  }

  FutureOr<void> _onNoteChange(NoteChange event, Emitter<WorkLogState> emit) {
    emit(state.copyWith(note: event.note));
  }

  FutureOr<void> _onServiceDateChange(
    ServiceDateChange event,
    Emitter<WorkLogState> emit,
  ) {
    emit(state.copyWith(serviceDate: event.date));
  }

  FutureOr<void> _onRemovePart(
    RemovePartEvent event,
    Emitter<WorkLogState> emit,
  ) {
    final updated = state.selectedParts
        .where((item) => item.partId != event.partId)
        .toList();
    emit(state.copyWith(selectedParts: updated));
  }

  FutureOr<void> _onUpdatePartItem(
    UpdatePartItemEvent event,
    Emitter<WorkLogState> emit,
  ) {
    final updated = state.selectedParts.map((item) {
      return item.partId == event.item.partId ? event.item : item;
    }).toList();
    emit(state.copyWith(selectedParts: updated));
  }

  void _onWizardStepChanged(
    WorkLogWizardStepChanged event,
    Emitter<WorkLogState> emit,
  ) {
    emit(state.copyWith(currentStep: event.step.clamp(0, 2).toInt()));
  }

  void _onPartsQueryChanged(
    PartsQueryChanged event,
    Emitter<WorkLogState> emit,
  ) {
    emit(state.copyWith(partsQuery: event.query));
  }

  void _onValidationRequested(
    WorkLogValidationRequested event,
    Emitter<WorkLogState> emit,
  ) {
    emit(state.copyWith(showValidationErrors: true));
  }
}
