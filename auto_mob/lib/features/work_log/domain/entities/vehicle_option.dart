import 'package:equatable/equatable.dart';

/// Voce leggera del veicolo per il dropdown dello storico lavori.
/// NON e' l'entita' Vehicle della dashboard (che porta KPI e ultimi km):
/// qui serve solo il minimo per popolare il selettore, senza creare
/// dipendenza dal modulo vehicle.
class VehicleOption extends Equatable {
  final String id;
  final String targa;
  final String nome; // modello
  final String brand;
  final int km;

  const VehicleOption({
    required this.id,
    required this.targa,
    required this.nome,
    required this.brand,
    required this.km,
  });

  @override
  List<Object?> get props => [id, targa, nome, brand, km];
}
