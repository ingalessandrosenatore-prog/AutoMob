import '../../domain/entities/vehicle_option.dart';

/// Mapping da riga `vehicles` (colonne minime) a [VehicleOption].
class VehicleOptionModel extends VehicleOption {
  const VehicleOptionModel({
    required super.id,
    required super.targa,
    required super.nome,
    required super.brand,
    required super.km,
  });

  factory VehicleOptionModel.fromJson(Map<String, dynamic> json) {
    return VehicleOptionModel(
      id: json['id'] as String,
      targa: (json['plate'] as String? ?? '').toUpperCase(),
      nome: (json['model'] as String? ?? '').toUpperCase(),
      brand: (json['brand'] as String? ?? '').toUpperCase(),
      km: (json['km_current'] as num?)?.toInt() ?? 0,
    );
  }
}
