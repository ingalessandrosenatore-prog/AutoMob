import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:equatable/equatable.dart';

enum WorkLogStatus { initial, loading, success, failure }

const _notProvided = Object();

class WorkLogState extends Equatable {
  final EnumPopUp type;
  final String? customName;
  final List<SelectedPart> selectedParts;
  final int currentKm;
  final int
  vehicleKm; // km attuali del veicolo: pavimento, il lavoro non può scendere sotto
  final int intervallKM;
  final int prosssimoRichiamo;
  final String note;
  final DateTime serviceDate;
  final WorkLogStatus status;
  final String? errorMessage;
  final String? errorCode;
  final int currentStep;
  final String partsQuery;
  final bool showValidationErrors;

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
    this.errorCode,
    this.currentStep = 0,
    this.partsQuery = '',
    this.showValidationErrors = false,
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

  double get partsTotal => selectedParts.fold<double>(
    0,
    (total, part) => total + part.quantity * (part.unitPrice ?? 0),
  );

  String? get kmValidationMessage =>
      showValidationErrors && currentKm < vehicleKm
      ? 'Inserisci almeno $vehicleKm km'
      : null;

  WorkLogState copyWith({
    EnumPopUp? type,
    Object? customName = _notProvided,
    List<SelectedPart>? selectedParts,
    int? currentKm,
    int? vehicleKm,
    int? intervallKM,
    String? note,
    int? prosssimoRichiamo,
    DateTime? serviceDate,
    WorkLogStatus? status,
    Object? errorMessage = _notProvided,
    Object? errorCode = _notProvided,
    int? currentStep,
    String? partsQuery,
    bool? showValidationErrors,
  }) {
    return WorkLogState(
      type: type ?? this.type,
      customName: identical(customName, _notProvided)
          ? this.customName
          : customName as String?,
      selectedParts: selectedParts ?? this.selectedParts,
      currentKm: currentKm ?? this.currentKm,
      vehicleKm: vehicleKm ?? this.vehicleKm,
      intervallKM: intervallKM ?? this.intervallKM,
      note: note ?? this.note,
      prosssimoRichiamo: prosssimoRichiamo ?? this.prosssimoRichiamo,
      serviceDate: serviceDate ?? this.serviceDate,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _notProvided)
          ? this.errorMessage
          : errorMessage as String?,
      errorCode: identical(errorCode, _notProvided)
          ? this.errorCode
          : errorCode as String?,
      currentStep: currentStep ?? this.currentStep,
      partsQuery: partsQuery ?? this.partsQuery,
      showValidationErrors: showValidationErrors ?? this.showValidationErrors,
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
    errorCode,
    currentStep,
    partsQuery,
    showValidationErrors,
  ];
}
