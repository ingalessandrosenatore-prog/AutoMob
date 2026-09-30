import 'package:automob_backoffice_mech/core/error/failure.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_catalog.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/repositories/workshop_repository.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/get_workshop_catalog.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_bloc.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_event.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_state.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_vehicle_filter.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

final class _MockRepository extends Mock implements WorkshopRepository {}

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  blocTest<WorkshopBloc, WorkshopState>(
    'carica il catalogo completo e rende visibili i primi 20',
    setUp: () => when(
      () => repository.getCatalog(),
    ).thenAnswer((_) async => Right(_catalog(45))),
    build: () =>
        WorkshopBloc(getWorkshopCatalog: GetWorkshopCatalog(repository)),
    act: (bloc) => bloc.add(const WorkshopStarted()),
    expect: () => [
      const WorkshopLoading(),
      isA<WorkshopReady>()
          .having((state) => state.allVehicles.length, 'all', 45)
          .having((state) => state.visibleVehicles.length, 'visible', 20),
    ],
  );

  blocTest<WorkshopBloc, WorkshopState>(
    'filtra tutta la lista per marca modello e targa normalizzata',
    setUp: () => when(
      () => repository.getCatalog(),
    ).thenAnswer((_) async => Right(_catalog(30))),
    build: () =>
        WorkshopBloc(getWorkshopCatalog: GetWorkshopCatalog(repository)),
    act: (bloc) async {
      bloc.add(const WorkshopStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WorkshopSearchChanged('fiat ab-100-xy'));
    },
    skip: 2,
    expect: () => [
      isA<WorkshopReady>()
          .having((state) => state.filteredVehicles.length, 'filtered', 1)
          .having((state) => state.visibleCount, 'window reset', 20),
    ],
  );

  blocTest<WorkshopBloc, WorkshopState>(
    'aumenta la finestra di 20 e ignora richieste duplicate obsolete',
    setUp: () => when(
      () => repository.getCatalog(),
    ).thenAnswer((_) async => Right(_catalog(45))),
    build: () =>
        WorkshopBloc(getWorkshopCatalog: GetWorkshopCatalog(repository)),
    act: (bloc) async {
      bloc.add(const WorkshopStarted());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const WorkshopVisibleWindowRequested(20))
        ..add(const WorkshopVisibleWindowRequested(20));
    },
    skip: 2,
    expect: () => [
      isA<WorkshopReady>().having(
        (state) => state.visibleVehicles.length,
        'visible',
        40,
      ),
    ],
  );

  blocTest<WorkshopBloc, WorkshopState>(
    'combina filtro manutenzione e ricerca testuale',
    setUp: () => when(
      () => repository.getCatalog(),
    ).thenAnswer((_) async => Right(_filterCatalog())),
    build: () =>
        WorkshopBloc(getWorkshopCatalog: GetWorkshopCatalog(repository)),
    act: (bloc) async {
      bloc.add(const WorkshopStarted());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(
          const WorkshopVehicleFilterChanged(
            WorkshopVehicleFilter.maintenanceDue,
          ),
        )
        ..add(const WorkshopSearchChanged('fiat'));
    },
    skip: 2,
    expect: () => [
      isA<WorkshopReady>()
          .having(
            (state) => state.filter,
            'filter',
            WorkshopVehicleFilter.maintenanceDue,
          )
          .having((state) => state.filteredVehicles.length, 'due', 2),
      isA<WorkshopReady>()
          .having(
            (state) => state.filter,
            'filter kept',
            WorkshopVehicleFilter.maintenanceDue,
          )
          .having((state) => state.filteredVehicles.length, 'query', 1),
    ],
  );

  blocTest<WorkshopBloc, WorkshopState>(
    'espone il messaggio del failure per il popup UI',
    setUp: () => when(
      () => repository.getCatalog(),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    build: () =>
        WorkshopBloc(getWorkshopCatalog: GetWorkshopCatalog(repository)),
    act: (bloc) => bloc.add(const WorkshopStarted()),
    expect: () => [
      const WorkshopLoading(),
      isA<WorkshopLoadFailure>().having(
        (state) => state.message,
        'message',
        'Connessione assente. Controlla la rete e riprova.',
      ),
    ],
  );
}

WorkshopCatalog _catalog(int count) => WorkshopCatalog(
  mechanic: const WorkshopMechanic(displayName: 'Marco'),
  vehicles: List.generate(
    count,
    (index) => WorkshopVehicle(
      id: 'vehicle-$index',
      plate: index == 0 ? 'AB100XY' : 'ZZ${index}ZZ',
      brand: index == 0 ? 'Fiat' : 'Brand $index',
      model: index == 0 ? 'Panda' : 'Model $index',
      year: 2020,
      kmCurrent: 100000,
      tagliandoIntervalKm: 15000,
      requiresMaintenance: false,
    ),
  ),
);

WorkshopCatalog _filterCatalog() => const WorkshopCatalog(
  mechanic: WorkshopMechanic(displayName: 'Marco'),
  vehicles: [
    WorkshopVehicle(
      id: 'fiat-due',
      plate: 'AA111AA',
      brand: 'Fiat',
      model: 'Panda',
      year: 2020,
      kmCurrent: 100000,
      tagliandoIntervalKm: 15000,
      lastTagliandoKm: 80000,
      requiresMaintenance: true,
    ),
    WorkshopVehicle(
      id: 'alfa-due',
      plate: 'BB222BB',
      brand: 'Alfa Romeo',
      model: 'Tonale',
      year: 2022,
      kmCurrent: 40000,
      tagliandoIntervalKm: 15000,
      lastTagliandoKm: 20000,
      requiresMaintenance: true,
    ),
    WorkshopVehicle(
      id: 'fiat-ok',
      plate: 'CC333CC',
      brand: 'Fiat',
      model: '500',
      year: 2023,
      kmCurrent: 10000,
      tagliandoIntervalKm: 15000,
      requiresMaintenance: false,
    ),
  ],
);
