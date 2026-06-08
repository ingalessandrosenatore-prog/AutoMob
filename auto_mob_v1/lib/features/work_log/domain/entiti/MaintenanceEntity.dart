// ============================================================
// domain/entities/maintenance_record.dart
// ============================================================

import 'package:auto_mob_v1/core/types/EnumPopUp.dart';

class MaintenanceRecord {
  final String? id;
  final String vehicleId;
  final String? mechanicId;
  final DateTime serviceDate;
  final String? notes;


  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceDate,
    this.mechanicId,
    this.notes,
  });
}

// ============================================================
// domain/entities/maintenance_item.dart
// ============================================================



class MaintenanceItem {
  final String id;
  final String recordId;
  final EnumPopUp type;
  final String? customName;
  final int serviceKm;
  final DateTime serviceDate;
  final String? notes;


  const MaintenanceItem({
    required this.id,
    required this.recordId,
    required this.type,
    this.customName,
    required this.serviceKm,
    required this.serviceDate,
    this.notes,
  });
}

// ============================================================
// domain/entities/maintenance_item_part.dart
// ============================================================

class MaintenanceItemPart {
  final String id;
  final String itemId;
  final int partId;
  final double quantity;
  final double? unitPrice;
  final String? notes;

  const MaintenanceItemPart({
    required this.id,
    required this.itemId,
    required this.partId,
    required this.quantity ,
    this.unitPrice,
    this.notes,
  });
}