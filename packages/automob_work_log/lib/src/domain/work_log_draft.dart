import 'package:equatable/equatable.dart';

class WorkLogPartDraft extends Equatable {
  const WorkLogPartDraft({
    required this.partId,
    this.quantity = 1,
    this.unitPrice,
    this.notes,
  });
  final int partId;
  final double quantity;
  final double? unitPrice;
  final String? notes;

  double get subtotal => quantity * (unitPrice ?? 0);

  WorkLogPartDraft copyWith({
    double? quantity,
    double? unitPrice,
    String? notes,
    bool clearUnitPrice = false,
    bool clearNotes = false,
  }) => WorkLogPartDraft(
    partId: partId,
    quantity: quantity ?? this.quantity,
    unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
    notes: clearNotes ? null : notes ?? this.notes,
  );
  @override
  List<Object?> get props => [partId, quantity, unitPrice, notes];
}

class WorkLogDraft extends Equatable {
  const WorkLogDraft({
    required this.vehicleId,
    required this.type,
    required this.serviceKm,
    required this.serviceDate,
    this.customName,
    this.notes,
    this.intervalKm,
    this.parts = const [],
  });
  final String vehicleId;
  final String type;
  final String? customName;
  final int serviceKm;
  final DateTime serviceDate;
  final String? notes;
  final int? intervalKm;
  final List<WorkLogPartDraft> parts;
  @override
  List<Object?> get props => [
    vehicleId,
    type,
    customName,
    serviceKm,
    serviceDate,
    notes,
    intervalKm,
    parts,
  ];
}
