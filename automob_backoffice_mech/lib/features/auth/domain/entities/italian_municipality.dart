import 'package:equatable/equatable.dart';

base class ItalianMunicipality extends Equatable {
  const ItalianMunicipality({
    required this.code,
    required this.name,
    required this.provinceCode,
    required this.provinceName,
  });

  final String code;
  final String name;
  final String provinceCode;
  final String provinceName;

  String get label => '$name ($provinceCode)';

  @override
  List<Object?> get props => [code, name, provinceCode, provinceName];
}
