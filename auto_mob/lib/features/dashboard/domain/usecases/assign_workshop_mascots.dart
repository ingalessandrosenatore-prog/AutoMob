import 'dart:math';

import '../../../vehicle/domain/entities/vehicle.dart';
import '../entities/workshop_mascot.dart';

/// Una scelta casuale per officina all'avvio; il refresh riusa la stessa scelta.
class AssignWorkshopMascots {
  AssignWorkshopMascots({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, WorkshopMascot> _session = {};
  final List<(String, String)> _remainingPalettes = [];

  static const _palettes = [
    ('#252930', '#ff7926'),
    ('#202c43', '#3189ff'),
    ('#302429', '#ed4848'),
    ('#303030', '#ffb026'),
  ];

  Map<String, List<WorkshopMascot>> call(List<Vehicle> vehicles) => {
    for (final vehicle in vehicles)
      vehicle.id: [
        for (final mechanic in vehicle.mechanics)
          _session.putIfAbsent(mechanic.id, () => _create(mechanic.id)),
      ],
  };

  WorkshopMascot _create(String mechanicId) {
    final pose = _random.nextBool() ? 'standing' : 'desk';
    final props = pose == 'standing'
        ? const ['wrench', 'screwdriver', 'tablet', 'tire']
        : const ['wrench', 'screwdriver', 'tablet'];
    // Estrazione senza reinserimento: niente doppioni finché il giro di
    // palette non è finito. Il refresh non cambia le assegnazioni esistenti.
    if (_remainingPalettes.isEmpty) {
      _remainingPalettes.addAll(_palettes.toList()..shuffle(_random));
    }
    final palette = _remainingPalettes.removeLast();
    return WorkshopMascot(
      mechanicId: mechanicId,
      pose: pose,
      prop: props[_random.nextInt(props.length)],
      baseColor: palette.$1,
      accentColor: palette.$2,
    );
  }
}
