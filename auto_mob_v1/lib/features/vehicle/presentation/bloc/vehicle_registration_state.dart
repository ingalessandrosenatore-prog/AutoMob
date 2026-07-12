import 'package:equatable/equatable.dart';
import '../../domain/entities/vehicle_draft.dart';

enum RegistrationLookupStatus { idle, loading, success, notFound }

enum RegistrationStatus { idle, loading, completed }

class VehicleRegistrationState extends Equatable {
  final int currentStep;
  final VehicleDraft draft;
  final RegistrationLookupStatus lookupStatus;
  final RegistrationStatus status;

  static const int totalSteps = 5;

  const VehicleRegistrationState({
    this.currentStep = 0,
    this.draft = const VehicleDraft(),
    this.lookupStatus = RegistrationLookupStatus.idle,
    this.status = RegistrationStatus.idle,
  });

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == totalSteps - 1;

  VehicleRegistrationState copyWith({
    int? currentStep,
    VehicleDraft? draft,
    RegistrationLookupStatus? lookupStatus,
    RegistrationStatus? status,
  }) {
    return VehicleRegistrationState(
      currentStep: currentStep ?? this.currentStep,
      draft: draft ?? this.draft,
      lookupStatus: lookupStatus ?? this.lookupStatus,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [currentStep, draft, lookupStatus, status];
}
