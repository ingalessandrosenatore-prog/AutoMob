import 'package:equatable/equatable.dart';

import 'work_log_part.dart';
import 'work_log_type.dart';

class WorkLogEntry extends Equatable {
  const WorkLogEntry({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.serviceKm,
    required this.serviceDate,
    this.customName,
    this.notes,
    this.intervalKm,
    this.hasWorkshop = false,
    this.workshopName,
    this.parts = const [],
  });
  final String id;
  final String vehicleId;
  final String type;
  final int serviceKm;
  final DateTime serviceDate;
  final String? customName;
  final String? notes;
  final int? intervalKm;
  final bool hasWorkshop;
  final String? workshopName;
  final List<WorkLogPart> parts;

  String get title {
    final custom = customName?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return WorkLogType.tryFromWire(type)?.label ?? type;
  }

  int get partsTotalCents =>
      parts.fold(0, (total, part) => total + (part.subtotalCents ?? 0));

  bool get hasKmDeadline =>
      const {
        'tagliando',
        'distribuzione',
        'pneumatici_cambio',
        'pneumatici_inversione',
      }.contains(type) &&
      (intervalKm ?? 0) > 0;

  int? remainingKmAt(int? currentKm) {
    if (!hasKmDeadline || currentKm == null) return null;
    return serviceKm + intervalKm! - currentKm;
  }

  bool? isExpiredAt(int? currentKm) {
    final remainingKm = remainingKmAt(currentKm);
    return remainingKm == null ? null : remainingKm <= 0;
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    type,
    serviceKm,
    serviceDate,
    customName,
    notes,
    intervalKm,
    hasWorkshop,
    workshopName,
    parts,
  ];
}
