import 'package:equatable/equatable.dart';

import '../../../../core/types/EnumPopUp.dart';

sealed class  WorkLogEvent extends Equatable{

  @override
  List<Object?> get props => [];
}


class WorkLogEventCohiceTap extends WorkLogEvent{

  final bool isSelected;
  final int id;

  WorkLogEventCohiceTap({required this.isSelected, required this.id});

  @override
  List<Object?> get props => [isSelected, id];
}

class CurrentKmChange extends WorkLogEvent{
  final int currentKm;
  CurrentKmChange({required this.currentKm});

  @override
  List<Object?> get props => [currentKm];
}

class  RichiamoChange extends WorkLogEvent{
  final int intervallKM;
  RichiamoChange({ required this.intervallKM});

  @override
  List<Object?> get props => [intervallKM];


}

class OnSubmitEvent extends WorkLogEvent{

  final EnumPopUp type;
  final Set<int> selectedParts;
  final int currentKm;
  final int intervallKM;
  final String note;
  final int prosssimoRichiamo;

  OnSubmitEvent({required this.type, required this.selectedParts, required this.currentKm, required this.intervallKM, required this.note, required this.prosssimoRichiamo});

}

class OnWorkTypeChange extends WorkLogEvent{
     final EnumPopUp type;

     OnWorkTypeChange({required this.type});

     @override
     List<Object?> get props => [type];

}