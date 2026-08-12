import 'package:equatable/equatable.dart';

import 'mechanic_summary.dart';
import 'vehicle_mileage_estimate.dart';

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
  final DateTime? kmUpdatedAt;
  final DateTime? nextRevisionDate;

  // intervalli di manutenzione: popolati dal DB con default (15000/40000/10000).
  // read-only per ora, in futuro li chiederemo nel wizard.
  final int tagliandoIntervalKm;
  final int tireChangeIntervalKm;
  final int tireRotationIntervalKm;
  final int? distribuzioneIntervalKm;

  // km e data dell'ultimo intervento per tipo (null se mai eseguita).
  final int? lastTagliandoKm;
  final DateTime? lastTagliandoDate;
  final int? lastDistribuzioneKm;
  final DateTime? lastDistribuzioneDate;
  final int? lastTireChangeKm;
  final DateTime? lastTireChangeDate;
  final int? lastTireRotationKm;
  final DateTime? lastTireRotationDate;
  final DateTime? lastRevisionDate;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<MechanicSummary> mechanics;

  /// Compatibilita' temporanea per i consumer ancora basati su una sola
  /// officina. La lista ordinata resta la fonte di verita'.
  MechanicSummary? get mechanic => mechanics.isEmpty ? null : mechanics.first;

  /// Path locale della foto del veicolo (es. /data/.../foto_veicoli/veicolo_AB123CD.jpg).
  /// Null se la foto non è stata salvata. Non viene persistito su DB.
  final String? fotoPath;

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
    this.distribuzioneIntervalKm,
    this.powerCv,
    this.displacementCc,
    this.kmUpdatedAt,
    this.nextRevisionDate,
    this.lastTagliandoKm,
    this.lastTagliandoDate,
    this.lastDistribuzioneKm,
    this.lastDistribuzioneDate,
    this.lastTireChangeKm,
    this.lastTireChangeDate,
    this.lastTireRotationKm,
    this.lastTireRotationDate,
    this.lastRevisionDate,
    this.updatedAt,
    this.fotoPath,
    this.mechanics = const [],
  });

  Vehicle copyWith({String? fotoPath, List<MechanicSummary>? mechanics}) {
    return Vehicle(
      id: id,
      ownerId: ownerId,
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      fuel: fuel,
      kmCurrent: kmCurrent,
      kmUpdatedAt: kmUpdatedAt,
      tagliandoIntervalKm: tagliandoIntervalKm,
      tireChangeIntervalKm: tireChangeIntervalKm,
      tireRotationIntervalKm: tireRotationIntervalKm,
      distribuzioneIntervalKm: distribuzioneIntervalKm,
      createdAt: createdAt,
      powerCv: powerCv,
      displacementCc: displacementCc,
      nextRevisionDate: nextRevisionDate,
      lastTagliandoKm: lastTagliandoKm,
      lastTagliandoDate: lastTagliandoDate,
      lastDistribuzioneKm: lastDistribuzioneKm,
      lastDistribuzioneDate: lastDistribuzioneDate,
      lastTireChangeKm: lastTireChangeKm,
      lastTireChangeDate: lastTireChangeDate,
      lastTireRotationKm: lastTireRotationKm,
      lastTireRotationDate: lastTireRotationDate,
      lastRevisionDate: lastRevisionDate,
      updatedAt: updatedAt,
      fotoPath: fotoPath ?? this.fotoPath,
      mechanics: mechanics ?? this.mechanics,
    );
  }

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

  VehicleMileageEstimate mileageEstimateAt(DateTime now) {
    return VehicleMileageEstimate.calculate(
      currentKm: kmCurrent,
      vehicleYear: year,
      lastKmUpdateAt: kmUpdatedAt,
      now: now,
    );
  }

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
    kmUpdatedAt,
    nextRevisionDate,
    tagliandoIntervalKm,
    tireChangeIntervalKm,
    tireRotationIntervalKm,
    distribuzioneIntervalKm,
    lastTagliandoKm,
    lastTagliandoDate,
    lastDistribuzioneKm,
    lastDistribuzioneDate,
    lastTireChangeKm,
    lastTireChangeDate,
    lastTireRotationKm,
    lastTireRotationDate,
    lastRevisionDate,
    createdAt,
    updatedAt,
    fotoPath,
    mechanics,
  ];
}
