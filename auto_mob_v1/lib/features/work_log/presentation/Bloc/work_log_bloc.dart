import 'dart:async';

import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/domain/entiti/WorkLogItemEntity.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkLogBloc extends Bloc<WorkLogEvent, WorkLogState> {

  WorkLogBloc() : super(WorkLogState(type: EnumPopUp.altro, selectedParts: [], currentKm: 0, intervallKM: 0, note: "", prosssimoRichiamo: 0)) {
    on<WorkLogEventCohiceTap>(_onTspOnChoice);
    on<OnSubmitEvent>(_onSubmitEvent);
    on<CurrentKmChange>(_onKmChange);
    on<RichiamoChange>(_onRichiamoChange);
    on<OnWorkTypeChange>(_onWorkTypeChange);
    on<RemovePartEvent>(_onRemovePart);
    on<UpdatePartItemEvent>(_onUpdatePartItem);
  }

  FutureOr<void> _onTspOnChoice(WorkLogEventCohiceTap event, Emitter<WorkLogState> emit) {
    final current = List<WorkLogItem>.from(state.selectedParts);
    final alreadySelected = current.any((item) => item.partId == event.id);
    if (alreadySelected) {
      current.removeWhere((item) => item.partId == event.id);
    } else {
      current.add(WorkLogItem(
        id: event.id,
        partId: event.id,
        km: state.currentKm,
        date: DateTime.now(),
        partQuantity: 1,
      ));
    }
    emit(state.copyWith(selectedParts: current));
  }

  FutureOr<void> _onSubmitEvent(OnSubmitEvent event, Emitter<WorkLogState> emit) {
    // TODO: implementare salvataggio via usecase (layer dati)
  }

  FutureOr<void> _onKmChange(CurrentKmChange event, Emitter<WorkLogState> emit) {
    emit(state.copyWith(
      currentKm: event.currentKm,
      prosssimoRichiamo: event.currentKm + state.intervallKM,
    ));
  }

  FutureOr<void> _onRichiamoChange(RichiamoChange event, Emitter<WorkLogState> emit) {
    emit(state.copyWith(
      prosssimoRichiamo: state.currentKm + event.intervallKM,
      intervallKM: event.intervallKM,
    ));
  }

  FutureOr<void> _onWorkTypeChange(OnWorkTypeChange event, Emitter<WorkLogState> emit) {
    emit(state.copyWith(type: event.type));
  }

  FutureOr<void> _onRemovePart(RemovePartEvent event, Emitter<WorkLogState> emit) {
    final updated = state.selectedParts.where((item) => item.partId != event.partId).toList();
    emit(state.copyWith(selectedParts: updated));
  }

  FutureOr<void> _onUpdatePartItem(UpdatePartItemEvent event, Emitter<WorkLogState> emit) {
    final updated = state.selectedParts.map((item) {
      return item.partId == event.item.partId ? event.item : item;
    }).toList();
    emit(state.copyWith(selectedParts: updated));
  }
}
