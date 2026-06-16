import 'package:equatable/equatable.dart';

/// Una parte selezionata dentro un intervento.
/// Corrisponde 1:1 a una riga di `maintenance_item_parts` sul DB.
///
/// `partId` è l'identità: combacia con `parts.id` (bigint) e con la chiave
/// di [kPartsCatalog]. È l'unico campo usato per il matching (selezione,
/// update, rimozione) — niente più `id` ridondante.
class SelectedPart extends Equatable {
  final int partId;
  final double quantity;
  final double? unitPrice;
  final String? note;

  const SelectedPart({
    required this.partId,
    this.quantity = 1,
    this.unitPrice,
    this.note,
  });

  SelectedPart copyWith({
    int? partId,
    double? quantity,
    double? unitPrice,
    String? note,
  }) {
    return SelectedPart(
      partId: partId ?? this.partId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [partId, quantity, unitPrice, note];
}
