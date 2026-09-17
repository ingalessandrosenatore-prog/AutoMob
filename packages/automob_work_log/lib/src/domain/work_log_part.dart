import 'package:equatable/equatable.dart';

import 'work_log_parts_catalog.dart';

/// Ricambio associato a un intervento. I prezzi sono centesimi per evitare
/// calcoli monetari in virgola mobile nella UI.
class WorkLogPart extends Equatable {
  const WorkLogPart({
    required this.partId,
    required this.name,
    required this.quantity,
    this.unitPriceCents,
    this.notes,
    this.category,
  });

  final int partId;
  final String name;
  final double quantity;
  final int? unitPriceCents;
  final String? notes;
  final WorkLogPartCategory? category;

  int? get subtotalCents =>
      unitPriceCents == null ? null : (quantity * unitPriceCents!).round();

  @override
  List<Object?> get props => [
    partId,
    name,
    quantity,
    unitPriceCents,
    notes,
    category,
  ];
}
