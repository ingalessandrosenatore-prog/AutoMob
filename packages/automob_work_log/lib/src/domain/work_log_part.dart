import 'package:equatable/equatable.dart';

/// Ricambio associato a un intervento. I prezzi sono centesimi per evitare
/// calcoli monetari in virgola mobile nella UI.
class WorkLogPart extends Equatable {
  const WorkLogPart({
    required this.partId,
    required this.name,
    required this.quantity,
    this.unitPriceCents,
    this.notes,
  });

  final int partId;
  final String name;
  final double quantity;
  final int? unitPriceCents;
  final String? notes;

  int? get subtotalCents =>
      unitPriceCents == null ? null : (quantity * unitPriceCents!).round();

  @override
  List<Object?> get props => [partId, name, quantity, unitPriceCents, notes];
}
