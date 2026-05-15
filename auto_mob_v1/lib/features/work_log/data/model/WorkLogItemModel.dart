import 'package:auto_mob_v1/features/work_log/domain/entiti/WorkLogItemEntity.dart';

class WorkLogItemModel extends WorkLogItem {
  const WorkLogItemModel({
    required super.id,
    required super.km,
    required super.date,
    super.notes,
    required super.partId,
    super.partPrice,
    super.partNote,
    required super.partQuantity,
  });

  factory WorkLogItemModel.fromJson(Map<String, dynamic> json) {
    int intValue(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double doubleValue(dynamic v, {double fallback = 0}) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    double? doubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    DateTime date(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return WorkLogItemModel(
      id: intValue(json['id']),
      km: intValue(json['km']),
      date: date(json['date']),
      notes: json['notes'] as String?,
      partId: intValue(json['part_id']),
      partPrice: doubleOrNull(json['part_price']),
      partNote: json['part_note'] as String?,
      partQuantity: doubleValue(json['part_quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'km': km,
      'date': date.toIso8601String(),
      'notes': notes,
      'part_id': partId,
      'part_price': partPrice,
      'part_note': partNote,
      'part_quantity': partQuantity,
    };
  }
}
