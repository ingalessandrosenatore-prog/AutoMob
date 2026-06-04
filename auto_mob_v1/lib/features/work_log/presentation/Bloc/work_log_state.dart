import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/domain/entiti/WorkLogItemEntity.dart';
import 'package:equatable/equatable.dart';

enum WorkLogStatus { initial, loading, success, failure }

class WorkLogState extends Equatable {
  final EnumPopUp type;
  final String? customName;
  final List<WorkLogItem> selectedParts;
  final int currentKm;
  final int intervallKM;
  final int prosssimoRichiamo;
  final String note;
  final WorkLogStatus status;
  final String? errorMessage;

  const WorkLogState({
    required this.type,
    this.customName,
    required this.selectedParts,
    required this.currentKm,
    required this.intervallKM,
    required this.note,
    required this.prosssimoRichiamo,
    this.status = WorkLogStatus.initial,
    this.errorMessage,
  });

  factory WorkLogState.initial() => const WorkLogState(
        type: EnumPopUp.altro,
        selectedParts: [],
        currentKm: 0,
        intervallKM: 0,
        note: "",
        prosssimoRichiamo: 0,
      );

  WorkLogState copyWith({
    EnumPopUp? type,
    String? customName,
    List<WorkLogItem>? selectedParts,
    int? currentKm,
    int? intervallKM,
    String? note,
    int? prosssimoRichiamo,
    WorkLogStatus? status,
    String? errorMessage,
  }) {
    return WorkLogState(
      type: type ?? this.type,
      customName: customName ?? this.customName,
      selectedParts: selectedParts ?? this.selectedParts,
      currentKm: currentKm ?? this.currentKm,
      intervallKM: intervallKM ?? this.intervallKM,
      note: note ?? this.note,
      prosssimoRichiamo: prosssimoRichiamo ?? this.prosssimoRichiamo,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        type,
        customName,
        selectedParts,
        currentKm,
        intervallKM,
        note,
        prosssimoRichiamo,
        status,
        errorMessage,
      ];
}
