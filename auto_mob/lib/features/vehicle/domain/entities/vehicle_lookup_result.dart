import 'package:equatable/equatable.dart';

enum VehicleLookupQuality { complete, partial }

/// Dati normalizzati restituiti dalla Edge Function. Il payload grezzo resta
/// sul server: l'app conserva solo i campi utili e l'id dello snapshot.
class VehicleLookupResult extends Equatable {
  final String lookupId;
  final VehicleLookupQuality quality;
  final String plate;
  final String? marca;
  final String? modello;
  final int? anno;
  final String? carburante;
  final int? cilindrata;
  final int? potenzaCv;
  final List<String> warnings;

  const VehicleLookupResult({
    required this.lookupId,
    required this.quality,
    required this.plate,
    this.marca,
    this.modello,
    this.anno,
    this.carburante,
    this.cilindrata,
    this.potenzaCv,
    this.warnings = const [],
  });

  @override
  List<Object?> get props => [
    lookupId,
    quality,
    plate,
    marca,
    modello,
    anno,
    carburante,
    cilindrata,
    potenzaCv,
    warnings,
  ];
}
