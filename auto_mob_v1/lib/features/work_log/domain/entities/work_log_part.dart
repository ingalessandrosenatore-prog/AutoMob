import 'package:equatable/equatable.dart';

/// Ricambio associato a uno specifico item di manutenzione.
///
/// I prezzi restano in centesimi nel dominio, anche se Postgres li espone
/// come `numeric`, per evitare calcoli monetari in virgola mobile nella UI.
class WorkLogPart extends Equatable {
  final int partId;
  final String name;
  final double quantity;
  final int? unitPriceCents;
  final String? notes;

  const WorkLogPart({
    required this.partId,
    required this.name,
    required this.quantity,
    this.unitPriceCents,
    this.notes,
  });

  int? get subtotalCents =>
      unitPriceCents == null ? null : (quantity * unitPriceCents!).round();

  @override
  List<Object?> get props => [partId, name, quantity, unitPriceCents, notes];
}
