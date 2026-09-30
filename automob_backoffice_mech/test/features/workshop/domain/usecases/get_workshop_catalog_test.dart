import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_catalog.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/repositories/workshop_repository.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/get_workshop_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

final class _MockWorkshopRepository extends Mock
    implements WorkshopRepository {}

void main() {
  test(
    'calcola lo stato alla soglia esatta e ordina le urgenze prima',
    () async {
      final repository = _MockWorkshopRepository();
      final useCase = GetWorkshopCatalog(repository);
      final catalog = WorkshopCatalog(
        mechanic: const WorkshopMechanic(displayName: 'Marco'),
        vehicles: [
          _vehicle(id: 'ok', brand: 'Alfa', current: 119999, last: 105000),
          _vehicle(id: 'due', brand: 'Fiat', current: 120000, last: 105000),
        ],
      );
      when(
        () => repository.getCatalog(),
      ).thenAnswer((_) async => Right(catalog));

      final result = await useCase();
      final vehicles = result.getRight().toNullable()!.vehicles;

      expect(vehicles.map((vehicle) => vehicle.id), ['due', 'ok']);
      expect(vehicles.first.requiresMaintenance, isTrue);
      expect(vehicles.last.requiresMaintenance, isFalse);
    },
  );

  test('assenza dello storico non inventa una manutenzione scaduta', () async {
    final repository = _MockWorkshopRepository();
    final useCase = GetWorkshopCatalog(repository);
    final catalog = WorkshopCatalog(
      mechanic: const WorkshopMechanic(displayName: 'Marco'),
      vehicles: [_vehicle(id: 'unknown', current: 200000)],
    );
    when(() => repository.getCatalog()).thenAnswer((_) async => Right(catalog));

    final result = await useCase();

    expect(
      result.getRight().toNullable()!.vehicles.single.requiresMaintenance,
      isFalse,
    );
  });
}

WorkshopVehicle _vehicle({
  required String id,
  int current = 100000,
  int? last,
  String brand = 'Fiat',
}) => WorkshopVehicle(
  id: id,
  plate: 'AB123CD',
  brand: brand,
  model: 'Panda',
  year: 2022,
  kmCurrent: current,
  tagliandoIntervalKm: 15000,
  lastTagliandoKm: last,
  requiresMaintenance: false,
);
