import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:equatable/equatable.dart';

class WorkLogState extends Equatable {

  final EnumPopUp type;
  final Set<int> selectedParts;
  final int currentKm;
  final int intervallKM;
  final int prosssimoRichiamo;
  final String note;



WorkLogState({required this.type, required this.selectedParts, required this.currentKm, required this.intervallKM, required this.note, required this.prosssimoRichiamo});

  WorkLogState copyWith({
    EnumPopUp? type,
    Set <int>? selectedParts,
    int? currentKm,
    int? intervallKM,
    String? note,
     int? prosssimoRichiamo,
  }) {
    return WorkLogState(
      type: type ?? this.type,
      selectedParts: selectedParts ?? this.selectedParts,
      currentKm: currentKm ?? this.currentKm,
      intervallKM: intervallKM ?? this.intervallKM,
      note: note ?? this.note,
      prosssimoRichiamo: prosssimoRichiamo ?? this.prosssimoRichiamo,
    );
  }

  @override
  List<Object?> get props => [type, selectedParts, currentKm, intervallKM, note, prosssimoRichiamo];

}