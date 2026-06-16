import 'package:auto_mob_v1/core/types/EnumPopUp.dart';
import 'package:auto_mob_v1/features/work_log/domain/entiti/SelectedPart.dart';
import 'package:equatable/equatable.dart';

enum WorkLogStatus { initial, loading, success, failure }

class WorkLogState extends Equatable {
  final EnumPopUp type;
  final String? customName;
  final List<SelectedPart> selectedParts;
  final int currentKm;
  final int vehicleKm; // km attuali del veicolo: pavimento, il lavoro non può scendere sotto
  final int intervallKM;
  final int prosssimoRichiamo;
  final String note;
  final DateTime serviceDate;
  final WorkLogStatus status;
  final String? errorMessage;

  const WorkLogState({
    required this.type,
    this.customName,
    required this.selectedParts,
    required this.currentKm,
    required this.vehicleKm,
    required this.intervallKM,
    required this.note,
    required this.prosssimoRichiamo,
    required this.serviceDate,
    this.status = WorkLogStatus.initial,
    this.errorMessage,
  });

  factory WorkLogState.initial() => WorkLogState(
        type: EnumPopUp.altro,
        selectedParts: const [],
        currentKm: 0,
        vehicleKm: 0,
        intervallKM: 0,
        note: "",
        prosssimoRichiamo: 0,
        serviceDate: DateTime.now(),
      );

  WorkLogState copyWith({
    EnumPopUp? type,
    String? customName,
    List<SelectedPart>? selectedParts,
    int? currentKm,
    int? vehicleKm,
    int? intervallKM,
    String? note,
    int? prosssimoRichiamo,
    DateTime? serviceDate,
    WorkLogStatus? status,
    String? errorMessage,
  }) {
    return WorkLogState(
      type: type ?? this.type,
      customName: customName ?? this.customName,
      selectedParts: selectedParts ?? this.selectedParts,
      currentKm: currentKm ?? this.currentKm,
      vehicleKm: vehicleKm ?? this.vehicleKm,
      intervallKM: intervallKM ?? this.intervallKM,
      note: note ?? this.note,
      prosssimoRichiamo: prosssimoRichiamo ?? this.prosssimoRichiamo,
      serviceDate: serviceDate ?? this.serviceDate,
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
        vehicleKm,
        intervallKM,
        note,
        prosssimoRichiamo,
        serviceDate,
        status,
        errorMessage,
      ];
}
