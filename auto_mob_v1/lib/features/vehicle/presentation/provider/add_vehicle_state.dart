import 'package:equatable/equatable.dart';
import '../../domain/entities/vehicle_draft.dart';

enum AddVehicleStatus { idle, loading, saving, error, completed }

class AddVehicleState extends Equatable {
  final int currentStep;
  final VehicleDraft draft;
  final AddVehicleStatus status;
  final String? errorMessage;

  static const int totalSteps = 5;

  const AddVehicleState({
    this.currentStep = 0,
    this.draft = const VehicleDraft(),
    this.status = AddVehicleStatus.idle,
    this.errorMessage,
  });

  bool get isLastStep => currentStep == totalSteps - 1;
  bool get isFirstStep => currentStep == 0;

  AddVehicleState copyWith({
    int? currentStep,
    VehicleDraft? draft,
    AddVehicleStatus? status,
    String? errorMessage,
  }) {
    return AddVehicleState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [currentStep, draft, status, errorMessage];
}
