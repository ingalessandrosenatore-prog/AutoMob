import 'package:equatable/equatable.dart';

class WorkLogItem extends Equatable {
  final int id;
  final int km;
  final DateTime date;
  final String? notes;
  final int partId;
  final double? partPrice;
  final String? partNote;
  final double partQuantity;

  const WorkLogItem({
    required this.id,
    required this.km,
    required this.date,
    this.notes,
    required this.partId,
    this.partPrice,
    this.partNote,
    required this.partQuantity,
  });

  WorkLogItem copyWith({
    int? id,
    int? km,
    DateTime? date,
    String? notes,
    int? partId,
    double? partPrice,
    String? partNote,
    double? partQuantity,
  }) {
    return WorkLogItem(
      id: id ?? this.id,
      km: km ?? this.km,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      partId: partId ?? this.partId,
      partPrice: partPrice ?? this.partPrice,
      partNote: partNote ?? this.partNote,
      partQuantity: partQuantity ?? this.partQuantity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        km,
        date,
        notes,
        partId,
        partPrice,
        partNote,
        partQuantity,
      ];
}
