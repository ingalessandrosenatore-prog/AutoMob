import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  const vehicle = WorkLogVehicle(
    id: 'vehicle-1',
    name: 'Alfa Romeo Giulia',
    plate: 'AB123CD',
    currentKm: 42000,
  );

  testWidgets('owner mostra pull-down e piu senza FAB', (tester) async {
    final repository = _Repository(vehicles: const [vehicle]);

    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    expect(find.byKey(const Key('work-log-owner-vehicle-selector')), findsOne);
    expect(find.byKey(const Key('work-log-owner-add')), findsOne);
    expect(find.byKey(const Key('work-log-mechanic-fab')), findsNothing);
    final colors = AmThemeColors.of(
      tester.element(find.byKey(const Key('work-log-owner-add'))),
    );
    final addButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-owner-add')),
    );
    final selector = tester.widget<AmPullDownLG>(
      find.byKey(const Key('work-log-owner-vehicle-selector')),
    );
    expect(addButton.color, colors.accent);
    expect(addButton.iconColor, colors.textPrimary);
    expect(selector.backgroundColor, colors.background.withValues(alpha: 0.3));
    expect(repository.getVehiclesCalls, 1);
    expect(repository.requestedVehicleIds, ['vehicle-1']);
  });

  testWidgets('il pull-down owner cambia veicolo e ricarica lo storico', (
    tester,
  ) async {
    const secondVehicle = WorkLogVehicle(
      id: 'vehicle-2',
      name: 'Lancia Delta',
      plate: 'CD456EF',
      currentKm: 61000,
    );
    final repository = _Repository(vehicles: const [vehicle, secondVehicle]);

    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    await tester.tap(find.byKey(const Key('work-log-owner-vehicle-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancia Delta'));
    await tester.pumpAndSettle();

    expect(repository.requestedVehicleIds, ['vehicle-1', 'vehicle-2']);
    expect(find.text('LANCIA DELTA'), findsOneWidget);
  });

  testWidgets('mechanic mostra back notifiche e FAB senza caricare veicoli', (
    tester,
  ) async {
    final repository = _Repository(vehicles: const [vehicle]);
    var notifications = 0;

    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const MechanicWorkLogLaunch(vehicle: vehicle),
          dependencies: WorkLogDependencies(repository: repository),
          onNotificationsPressed: () => notifications++,
        ),
      ),
    );
    await _pumpFeature(tester);

    expect(find.byKey(const Key('work-log-mechanic-back')), findsOne);
    expect(find.byKey(const Key('work-log-mechanic-notifications')), findsOne);
    expect(find.byKey(const Key('work-log-mechanic-fab')), findsOne);
    expect(find.byKey(const Key('work-log-owner-add')), findsNothing);
    final colors = AmThemeColors.of(
      tester.element(find.byKey(const Key('work-log-mechanic-back'))),
    );
    final backButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-mechanic-back')),
    );
    final notificationsButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-mechanic-notifications')),
    );
    expect(backButton.color, colors.background.withValues(alpha: 0.3));
    expect(backButton.iconColor, colors.textPrimary);
    expect(notificationsButton.color, colors.background.withValues(alpha: 0.3));
    expect(notificationsButton.iconColor, colors.textPrimary);
    expect(repository.getVehiclesCalls, 0);
    expect(repository.requestedVehicleIds, ['vehicle-1']);

    await tester.tap(find.byKey(const Key('work-log-mechanic-notifications')));
    expect(notifications, 1);
  });

  testWidgets('piu owner e FAB mechanic aprono lo stesso wizard', (
    tester,
  ) async {
    final ownerRepository = _Repository(vehicles: const [vehicle]);
    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: ownerRepository),
        ),
      ),
    );
    await _pumpFeature(tester);
    await tester.tap(find.byKey(const Key('work-log-owner-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WorkLogWizardBody), findsOne);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));

    final mechanicRepository = _Repository(vehicles: const [vehicle]);
    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const MechanicWorkLogLaunch(vehicle: vehicle),
          dependencies: WorkLogDependencies(repository: mechanicRepository),
        ),
      ),
    );
    await _pumpFeature(tester);
    await tester.tap(find.byKey(const Key('work-log-mechanic-fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WorkLogWizardBody), findsOne);
  });

  testWidgets('ritorno dal dettaglio conserva lo storico senza spinner', (
    tester,
  ) async {
    final repository = _Repository(
      vehicles: const [vehicle],
      entries: [
        WorkLogEntry(
          id: 'work-1',
          vehicleId: vehicle.id,
          type: 'tagliando',
          serviceKm: vehicle.currentKm,
          serviceDate: DateTime(2026, 8, 12),
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const MechanicWorkLogLaunch(vehicle: vehicle),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    await tester.tap(find.byType(WorkLogItemCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WorkLogDetailBody), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(WorkLogDetailBody), findsNothing);
    expect(find.byType(WorkLogItemCard), findsOne);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.requestedVehicleIds, ['vehicle-1']);
  });

  testWidgets('la lista compare solo dopo il completamento della route', (
    tester,
  ) async {
    final repository = _Repository(
      vehicles: const [vehicle],
      entries: _entries(10, vehicle.id),
    );
    late final _SlowMaterialPageRoute<void> historyRoute;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  historyRoute = _SlowMaterialPageRoute(
                    builder: (_) => WorkLogFeature(
                      launch: const MechanicWorkLogLaunch(vehicle: vehicle),
                      dependencies: WorkLogDependencies(repository: repository),
                    ),
                  );
                  Navigator.of(context).push<void>(historyRoute);
                },
                child: const Text('Apri storico'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri storico'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(historyRoute.animation?.status, AnimationStatus.forward);
    expect(historyRoute.animation?.value, lessThan(1));
    expect(repository.requestedRanges, const [(from: 0, to: 19)]);
    expect(find.byType(WorkLogItemCard), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(WorkLogItemCard), findsWidgets);
  });

  testWidgets('lo scroll carica automaticamente pagine da 20 lavori', (
    tester,
  ) async {
    final repository = _Repository(
      vehicles: const [vehicle],
      entries: _entries(45, vehicle.id),
    );

    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const MechanicWorkLogLaunch(vehicle: vehicle),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    expect(repository.requestedRanges, const [(from: 0, to: 19)]);

    await tester.fling(find.byType(ListView), const Offset(0, -3000), 2000);
    await tester.pumpAndSettle();
    expect(repository.requestedRanges, contains(const (from: 20, to: 39)));

    await tester.fling(find.byType(ListView), const Offset(0, -5000), 2000);
    await tester.pumpAndSettle();
    expect(repository.requestedRanges, const [
      (from: 0, to: 19),
      (from: 20, to: 39),
      (from: 40, to: 59),
    ]);
  });

  testWidgets('lo storico lascia 200 pixel prima della prima card', (
    tester,
  ) async {
    final repository = _Repository(
      vehicles: const [vehicle],
      entries: _entries(1, vehicle.id),
    );

    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const MechanicWorkLogLaunch(vehicle: vehicle),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    final spacing = tester.widget<SizedBox>(
      find.byKey(const Key('work-log-history-top-spacing')),
    );
    expect(spacing.height, 200);
    expect(find.byType(WorkLogItemCard), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(theme: AmTheme.dark, home: home);

Future<void> _pumpFeature(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

List<WorkLogEntry> _entries(int count, String vehicleId) => List.generate(
  count,
  (index) => WorkLogEntry(
    id: 'work-$index',
    vehicleId: vehicleId,
    type: 'tagliando',
    serviceKm: 42000 + index,
    serviceDate: DateTime(2026, 8, 12).subtract(Duration(days: index)),
  ),
);

class _Repository implements WorkLogRepository {
  _Repository({required this.vehicles, this.entries = const []});

  final List<WorkLogVehicle> vehicles;
  final List<WorkLogEntry> entries;
  int getVehiclesCalls = 0;
  final List<String> requestedVehicleIds = [];
  final List<({int from, int to})> requestedRanges = [];

  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) async =>
      right(unit);

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async {
    requestedVehicleIds.add(vehicleId);
    requestedRanges.add((from: from, to: to));
    if (from >= entries.length) return right(const []);
    return right(entries.sublist(from, (to + 1).clamp(0, entries.length)));
  }

  @override
  Future<Either<String, List<WorkLogVehicle>>> getVehicles() async {
    getVehiclesCalls++;
    return right(vehicles);
  }
}

class _SlowMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _SlowMaterialPageRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 600);
}
