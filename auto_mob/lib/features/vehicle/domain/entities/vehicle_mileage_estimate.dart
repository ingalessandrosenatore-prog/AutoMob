import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class VehicleMileageEstimate extends Equatable {
  const VehicleMileageEstimate({
    required this.averageKmPerDay,
    required this.daysSinceUpdate,
    required this.additionalKm,
    required this.estimatedKm,
  });

  factory VehicleMileageEstimate.calculate({
    required int currentKm,
    required int vehicleYear,
    required DateTime? lastKmUpdateAt,
    required DateTime now,
  }) {
    final normalizedCurrentKm = math.max(0, currentKm);
    final ageInYears = math.max(1, now.year - vehicleYear);
    final vehicleAgeInDays = ageInYears * 365;
    final averageKmPerDay = normalizedCurrentKm / vehicleAgeInDays;
    final daysSinceUpdate = lastKmUpdateAt == null
        ? 0
        : math.max(0, now.difference(lastKmUpdateAt).inDays);
    final additionalKm = (averageKmPerDay * daysSinceUpdate).round();

    return VehicleMileageEstimate(
      averageKmPerDay: averageKmPerDay,
      daysSinceUpdate: daysSinceUpdate,
      additionalKm: additionalKm,
      estimatedKm: normalizedCurrentKm + additionalKm,
    );
  }

  final double averageKmPerDay;
  final int daysSinceUpdate;
  final int additionalKm;
  final int estimatedKm;

  @override
  List<Object?> get props => [
    averageKmPerDay,
    daysSinceUpdate,
    additionalKm,
    estimatedKm,
  ];
}
