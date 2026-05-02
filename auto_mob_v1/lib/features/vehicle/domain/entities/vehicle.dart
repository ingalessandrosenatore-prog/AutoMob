import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String id;
  final String ownerId;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final String fuel;
  final int? powerCv;
  final int? displacementCc;
  final int kmCurrent;
  final DateTime? nextRevisionDate;

  // intervalli di manutenzione: popolati dal DB con default (15000/40000/10000).
  // read-only per ora, in futuro li chiederemo nel wizard.
  final int tagliandoIntervalKm;
  final int tireChangeIntervalKm;
  final int tireRotationIntervalKm;

  // km dell'ultima manutenzione per tipo (null se mai eseguita).
  // Letti dalla tabella maintenance_items, valore piu' recente per type.
  final int? lastTagliandoKm;
  final int? lastDistribuzioneKm;
  final int? lastTireChangeKm;
  final int? lastTireRotationKm;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const Vehicle({
    required this.id,
    required this.ownerId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuel,
    required this.kmCurrent,
    required this.tagliandoIntervalKm,
    required this.tireChangeIntervalKm,
    required this.tireRotationIntervalKm,
    required this.createdAt,
    this.powerCv,
    this.displacementCc,
    this.nextRevisionDate,
    this.lastTagliandoKm,
    this.lastDistribuzioneKm,
    this.lastTireChangeKm,
    this.lastTireRotationKm,
    this.updatedAt,
  });

  /// Placeholder usato dalla dashboard quando l'utente non ha ancora veicoli.
  /// Solo `model` valorizzato col messaggio, tutti gli altri campi a sentinel vuoti/zero.
  factory Vehicle.placeholder({
    String message = 'Non ci sono veicoli, aggiungili',
  }) {
    return Vehicle(
      id: '',
      ownerId: '',
      plate: '',
      brand: '',
      model: message,
      year: 0,
      fuel: '',
      kmCurrent: 0,
      tagliandoIntervalKm: 0,
      tireChangeIntervalKm: 0,
      tireRotationIntervalKm: 0,
      createdAt: DateTime(1970),
    );
  }

  /// `true` se l'oggetto e' un placeholder (id vuoto).
  bool get isPlaceholder => id.isEmpty;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        plate,
        brand,
        model,
        year,
        fuel,
        powerCv,
        displacementCc,
        kmCurrent,
        nextRevisionDate,
        tagliandoIntervalKm,
        tireChangeIntervalKm,
        tireRotationIntervalKm,
        lastTagliandoKm,
        lastDistribuzioneKm,
        lastTireChangeKm,
        lastTireRotationKm,
        createdAt,
        updatedAt,
      ];
}
