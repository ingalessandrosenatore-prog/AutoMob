import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/types/enum_pop_up.dart';

sealed class WorkLogEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WorkLogEventCohiceTap extends WorkLogEvent {
  final bool isSelected;
  final int id;

  WorkLogEventCohiceTap({required this.isSelected, required this.id});

  @override
  List<Object?> get props => [isSelected, id];
}

class CurrentKmChange extends WorkLogEvent {
  final int currentKm;
  CurrentKmChange({required this.currentKm});

  @override
  List<Object?> get props => [currentKm];
}

/// Inizializza i km del veicolo (pavimento + valore di partenza del campo).
class InitKm extends WorkLogEvent {
  final int vehicleKm;
  InitKm({required this.vehicleKm});

  @override
  List<Object?> get props => [vehicleKm];
}

class RichiamoChange extends WorkLogEvent {
  final int intervallKM;
  RichiamoChange({required this.intervallKM});

  @override
  List<Object?> get props => [intervallKM];
}

class NoteChange extends WorkLogEvent {
  final String note;
  NoteChange({required this.note});

  @override
  List<Object?> get props => [note];
}

class ServiceDateChange extends WorkLogEvent {
  final DateTime date;
  ServiceDateChange({required this.date});

  @override
  List<Object?> get props => [date];
}

class OnSubmitEvent extends WorkLogEvent {
  final String id ;
  OnSubmitEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class OnWorkTypeChange extends WorkLogEvent {
  final EnumPopUp type;

  OnWorkTypeChange({required this.type});

  @override
  List<Object?> get props => [type];
}

class CustomNameChange extends WorkLogEvent {
  final String customName;

  CustomNameChange({required this.customName});

  @override
  List<Object?> get props => [customName];
}

class RemovePartEvent extends WorkLogEvent {
  final int partId;

  RemovePartEvent({required this.partId});

  @override
  List<Object?> get props => [partId];
}

class UpdatePartItemEvent extends WorkLogEvent {
  final SelectedPart item;

  UpdatePartItemEvent({required this.item});

  @override
  List<Object?> get props => [item];
}
