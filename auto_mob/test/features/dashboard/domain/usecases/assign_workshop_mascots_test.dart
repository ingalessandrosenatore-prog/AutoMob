import 'dart:math';

import 'package:auto_mob_v1/features/dashboard/domain/usecases/assign_workshop_mascots.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mechanic = MechanicSummary(
    id: 'officina-1',
    code: '123456',
    businessName: 'Officina Uno',
  );

  test('assegna una variante valida e la mantiene dopo il refresh', () {
    final assign = AssignWorkshopMascots(random: Random(12));
    final vehicle = Vehicle.placeholder().copyWith(mechanics: const [mechanic]);
    final first = assign([vehicle])[vehicle.id]!.single;
    final refreshed = assign([vehicle])[vehicle.id]!.single;

    expect(refreshed, first);
    expect(first.mechanicId, mechanic.id);
    expect(first.baseColor, startsWith('#'));
    expect(first.accentColor, startsWith('#'));
    expect(
      first.pose == 'standing' || first.prop != 'tire',
      isTrue,
      reason: 'La gomma non è disponibile dietro al banco',
    );
  });

  test(
    'le prime quattro officine hanno colori distinti e stabili al riordino',
    () {
      final assign = AssignWorkshopMascots(random: Random(7));
      final mechanics = List.generate(
        4,
        (i) =>
            MechanicSummary(id: '$i', code: '$i', businessName: 'Officina $i'),
      );
      final vehicle = Vehicle.placeholder().copyWith(mechanics: mechanics);
      final first = assign([vehicle])[vehicle.id]!;
      expect(first.map((m) => m.accentColor).toSet(), hasLength(4));
      final next = assign([
        vehicle.copyWith(mechanics: mechanics.reversed.toList()),
      ])[vehicle.id]!;
      expect(next, first.reversed.toList());
    },
  );
}
