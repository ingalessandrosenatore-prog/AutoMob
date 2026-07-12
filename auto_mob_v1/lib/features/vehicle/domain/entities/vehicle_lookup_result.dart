import 'package:equatable/equatable.dart';

/// Dati veicolo restituiti dal lookup targa (marca/modello/anno/carburante/cilindrata).
class VehicleLookupResult extends Equatable {
  final String marca;
  final String modello;
  final int anno;
  final String carburante;
  final int cilindrata;

  const VehicleLookupResult({
    required this.marca,
    required this.modello,
    required this.anno,
    required this.carburante,
    required this.cilindrata,
  });

  @override
  List<Object?> get props => [marca, modello, anno, carburante, cilindrata];
}
