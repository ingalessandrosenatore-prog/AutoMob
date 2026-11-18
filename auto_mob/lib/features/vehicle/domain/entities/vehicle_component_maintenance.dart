import 'package:equatable/equatable.dart';

class VehicleComponentMaintenance extends Equatable {
  const VehicleComponentMaintenance({
    required this.partId,
    this.intervalKm,
    this.intervalYears,
    this.lastServiceKm,
    this.lastServiceDate,
  });

  final int partId;
  final int? intervalKm;
  final int? intervalYears;
  final int? lastServiceKm;
  final DateTime? lastServiceDate;

  @override
  List<Object?> get props => [
    partId,
    intervalKm,
    intervalYears,
    lastServiceKm,
    lastServiceDate,
  ];
}
