import 'dart:async';
import 'dart:math';

import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/Bloc/work_log_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkLogBloc extends Bloc<WorkLogEvent,WorkLogState>{



  WorkLogBloc() : super ( WorkLogState(type: EnumPopUp.altro , selectedParts: {}, currentKm: 0, intervallKM:0, note: "", prosssimoRichiamo: 0)) {
on<WorkLogEventCohiceTap>(_onTspOnChoice);
on<OnSubmitEvent>(_onSubmitEvent);
on<CurrentKmChange>(_onKmChange);
on<RichiamoChange>(_onRichiamoChange);
on<OnWorkTypeChange>(_onWorkTypeChange);
  }





  FutureOr<void> _onTspOnChoice(WorkLogEventCohiceTap event, Emitter<WorkLogState> emit) {
    final current = Set<int>.from(state.selectedParts);
    if (current.contains(event.id)) {
      current.remove(event.id);
    } else {
      current.add(event.id);
    }
    emit(state.copyWith(selectedParts: current));

  }

  FutureOr<void> _onSubmitEvent(OnSubmitEvent event, Emitter<WorkLogState> emit) {


  }

  FutureOr<void> _onKmChange(CurrentKmChange event, Emitter<WorkLogState> emit) {

    emit(state.copyWith(
      currentKm: event.currentKm,
        prosssimoRichiamo: event.currentKm + state.intervallKM));


  }

  FutureOr<void> _onRichiamoChange(RichiamoChange event, Emitter<WorkLogState> emit) {
    emit(state.copyWith(
      prosssimoRichiamo: state.currentKm + event.richiamoTra,
      intervallKM: event.richiamoTra,
    ));
  }

  FutureOr<void> _onWorkTypeChange(OnWorkTypeChange event, Emitter<WorkLogState> emit) {

    emit(state.copyWith(type: event.type));

  }
}