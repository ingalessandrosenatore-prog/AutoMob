import '../../domain/entities/italian_municipality.dart';

final class ItalianMunicipalityModel extends ItalianMunicipality {
  const ItalianMunicipalityModel({
    required super.code,
    required super.name,
    required super.provinceCode,
    required super.provinceName,
  });

  factory ItalianMunicipalityModel.fromJson(Map<String, Object?> json) =>
      ItalianMunicipalityModel(
        code: json['code']! as String,
        name: json['name']! as String,
        provinceCode: json['provinceCode']! as String,
        provinceName: json['provinceName']! as String,
      );
}
