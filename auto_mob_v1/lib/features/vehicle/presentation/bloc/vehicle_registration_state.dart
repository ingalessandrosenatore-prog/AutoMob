import 'package:equatable/equatable.dart';

import '../../domain/entities/vehicle_draft.dart';
import '../../domain/failures/vehicle_lookup_failure.dart';

enum RegistrationLookupStatus { idle, loading, complete, partial, failure }

enum MechanicLookupStatus { idle, loading, found, notFound, failure }

enum RegistrationStatus { idle, loading, completed, failure }

class VehicleRegistrationState extends Equatable {
  final int currentStep;
  final VehicleDraft draft;
  final RegistrationLookupStatus lookupStatus;
  final MechanicLookupStatus mechanicStatus;
  final RegistrationStatus status;
  final VehicleLookupFailure? lookupFailure;
  final String? message;
  final bool photoWarning;

  static const int totalSteps = 5;

  const VehicleRegistrationState({
    this.currentStep = 0,
    this.draft = const VehicleDraft(),
    this.lookupStatus = RegistrationLookupStatus.idle,
    this.mechanicStatus = MechanicLookupStatus.idle,
    this.status = RegistrationStatus.idle,
    this.lookupFailure,
    this.message,
    this.photoWarning = false,
  });

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep == totalSteps - 1;

  VehicleRegistrationState copyWith({
    int? currentStep,
    VehicleDraft? draft,
    RegistrationLookupStatus? lookupStatus,
    MechanicLookupStatus? mechanicStatus,
    RegistrationStatus? status,
    VehicleLookupFailure? lookupFailure,
    bool clearLookupFailure = false,
    String? message,
    bool clearMessage = false,
    bool? photoWarning,
  }) => VehicleRegistrationState(
    currentStep: currentStep ?? this.currentStep,
    draft: draft ?? this.draft,
    lookupStatus: lookupStatus ?? this.lookupStatus,
    mechanicStatus: mechanicStatus ?? this.mechanicStatus,
    status: status ?? this.status,
    lookupFailure: clearLookupFailure
        ? null
        : lookupFailure ?? this.lookupFailure,
    message: clearMessage ? null : message ?? this.message,
    photoWarning: photoWarning ?? this.photoWarning,
  );

  @override
  List<Object?> get props => [
    currentStep,
    draft,
    lookupStatus,
    mechanicStatus,
    status,
    lookupFailure,
    message,
    photoWarning,
  ];
}
