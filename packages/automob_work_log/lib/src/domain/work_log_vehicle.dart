import 'package:equatable/equatable.dart';

/// Dati minimi per scegliere un veicolo senza dipendere dalla feature Vehicle.
class WorkLogVehicle extends Equatable {
  const WorkLogVehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.currentKm,
  });

  final String id;
  final String name;
  final String plate;
  final int currentKm;

  @override
  List<Object?> get props => [id, name, plate, currentKm];
}
