import 'package:equatable/equatable.dart';

class VehicleSaveOutcome extends Equatable {
  final String vehicleId;
  final bool photoSaved;

  const VehicleSaveOutcome({required this.vehicleId, required this.photoSaved});

  @override
  List<Object> get props => [vehicleId, photoSaved];
}
