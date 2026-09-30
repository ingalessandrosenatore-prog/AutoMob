import 'package:automob_work_log/automob_work_log.dart';
import 'package:automob_work_log/src/presentation/work_log_type_selection_grid.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

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
    expect(find.byType(SmartEdge), findsNWidgets(2));
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
    expect(
      tester.getTopRight(find.byKey(const Key('work-log-owner-add'))).dx,
      MediaQuery.sizeOf(
        tester.element(find.byKey(const Key('work-log-owner-add'))),
      ).width,
    );
    expect(addButton.iconColor, isNull);
    expect(addButton.colorOpacity, 0.8);
    expect(addButton.iconWeight, 2.8);
    expect(
      find.descendant(
        of: find.byKey(const Key('work-log-owner-add')),
        matching: find.byType(Tooltip),
      ),
      findsNothing,
    );
    expect(
      selector.backgroundColor,
      AmControlMetrics.pullDownFill(
        Theme.of(tester.element(find.byType(WorkLogFeature))).brightness,
      ),
    );
    expect(addButton.routeAnimation, isNull);
    expect(selector.routeAnimation, isNull);
    expect(selector.ownsLiquidGlassGroup, isFalse);
    final glassGroup = tester.widget<OCLiquidGlassGroup>(
      find.byKey(const Key('work-log-history-glass-group')),
    );
    expect(glassGroup.repaint, same(selector.liquidGlassRepaint));
    expect(glassGroup.repaint, same(addButton.liquidGlassRepaint));
    expect(
      find.ancestor(
        of: find.byKey(const Key('work-log-owner-add')),
        matching: find.byType(OCLiquidGlassGroup),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('work-log-owner-vehicle-selector')),
        matching: find.byType(OCLiquidGlassGroup),
      ),
      findsOneWidget,
    );
    final appBarFinder = find
        .byWidgetPredicate(
          (widget) =>
              widget is PreferredSizeWidget &&
              widget.preferredSize.height == 69,
        )
        .first;
    final appBar = tester.widget<PreferredSizeWidget>(appBarFinder);
    expect(appBar.preferredSize.height, 69);
    expect(
      tester
              .getTopLeft(
                find.byKey(const Key('work-log-owner-vehicle-selector')),
              )
              .dy -
          tester.getTopLeft(appBarFinder).dy,
      closeTo(12.5, 0.01),
    );
    expect(repository.getVehiclesCalls, 1);
    expect(repository.requestedVehicleIds, ['vehicle-1']);
  });

  testWidgets('il selettore owner scompare e riappare insieme al suo glass', (
    tester,
  ) async {
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

    final opacityFinder = find.byKey(const Key('am-pull-down-morph-opacity'));
    Opacity triggerOpacity() => tester.widget<Opacity>(opacityFinder);

    expect(triggerOpacity().opacity, 1);
    expect(
      find.descendant(of: opacityFinder, matching: find.byType(OCLiquidGlass)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('work-log-owner-vehicle-selector')));
    await tester.pumpAndSettle();
    expect(triggerOpacity().opacity, closeTo(0, 0.001));
    final triggerLeft = tester
        .getTopLeft(find.byKey(const Key('work-log-owner-vehicle-selector')))
        .dx;
    final popupLeft = tester
        .getTopLeft(find.byKey(const Key('am-pull-down-popup-surface')))
        .dx;
    expect((popupLeft - triggerLeft).abs(), lessThanOrEqualTo(8));

    await tester.tap(find.text('ALFA ROMEO GIULIA').last);
    await tester.pump();
    expect(triggerOpacity().opacity, closeTo(0, 0.001));
    await tester.pump(const Duration(milliseconds: 100));
    expect(triggerOpacity().opacity, greaterThan(0));
    expect(triggerOpacity().opacity, lessThan(1));

    await tester.pumpAndSettle();
    expect(triggerOpacity().opacity, 1);
  });

  testWidgets('History owner condivide repaint tra gruppo e controlli', (
    tester,
  ) async {
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

    final selector = tester.widget<AmPullDownLG>(
      find.byKey(const Key('work-log-owner-vehicle-selector')),
    );
    final addButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-owner-add')),
    );
    final group = tester.widget<OCLiquidGlassGroup>(
      find.byKey(const Key('work-log-history-glass-group')),
    );

    expect(selector.ownsLiquidGlassGroup, isFalse);
    expect(selector.liquidGlassRepaint, same(addButton.liquidGlassRepaint));
    expect(group.repaint, same(selector.liquidGlassRepaint));
    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('work-log-owner-vehicle-selector')),
        matching: find.byType(OCLiquidGlassGroup),
      ),
      findsNothing,
    );

    var repaintNotifications = 0;
    var maxScale = 1.0;
    selector.liquidGlassRepaint!.addListener(() {
      repaintNotifications++;
      final scale = selector.liquidGlassRepaint!.scale;
      if (scale > maxScale) maxScale = scale;
    });
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const Key('work-log-owner-vehicle-selector')),
      ),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.cancel();
    await tester.pump();

    expect(repaintNotifications, greaterThan(0));
    expect(maxScale, greaterThan(1));
  });

  testWidgets('lo slide della shell ridipinge il glass della History', (
    tester,
  ) async {
    final routeAnimation = AnimationController.unbounded(
      vsync: const TestVSync(),
    );
    addTearDown(routeAnimation.dispose);
    final repository = _Repository(vehicles: const [vehicle]);

    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: repository),
          routeAnimation: routeAnimation,
        ),
      ),
    );
    await _pumpFeature(tester);

    final group = tester.widget<OCLiquidGlassGroup>(
      find.byKey(const Key('work-log-history-glass-group')),
    );
    final addButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-owner-add')),
    );
    final selector = tester.widget<AmPullDownLG>(
      find.byKey(const Key('work-log-owner-vehicle-selector')),
    );
    expect(addButton.liquidGlassRepaint, same(selector.liquidGlassRepaint));
    expect(group.repaint, same(addButton.liquidGlassRepaint));
    var notifications = 0;
    group.repaint!.addListener(() => notifications++);

    routeAnimation.value = 0.5;

    expect(notifications, 1);
    addButton.liquidGlassRepaint!.updateScale(1.1);
    expect(notifications, 2);

    final previousGlassRenderObject = tester.renderObject(
      find.byKey(const Key('work-log-history-glass-group')),
    );
    final replacementRepaint = AnimationController.unbounded(
      vsync: const TestVSync(),
    );
    addTearDown(replacementRepaint.dispose);
    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: repository),
          routeAnimation: replacementRepaint,
        ),
      ),
    );
    await _pumpFeature(tester);

    expect(
      tester.renderObject(
        find.byKey(const Key('work-log-history-glass-group')),
      ),
      isNot(same(previousGlassRenderObject)),
    );
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
    await tester.tap(find.text('LANCIA DELTA'));
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
    expect(notificationsButton.color, colors.accent.withValues(alpha: 0.3));
    expect(notificationsButton.iconColor, isNull);
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
    final wizardBack = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-wizard-back')),
    );
    final wizardColors = AmThemeColors.of(
      tester.element(find.byKey(const Key('work-log-wizard-back'))),
    );
    expect(wizardBack.color, wizardColors.background.withValues(alpha: 0.3));
    expect(wizardBack.iconColor, wizardColors.textPrimary);
    expect(wizardBack.routeAnimation, isNull);
    final wizardTitle = find.byKey(const Key('work-log-wizard-title'));
    final screenCenter = tester.getCenter(find.byType(Scaffold).last).dx;
    expect(tester.getCenter(wizardTitle).dx, screenCenter);
    expect(
      tester.getCenter(find.byKey(const Key('work-log-wizard-back'))).dx,
      lessThan(screenCenter),
    );
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

  testWidgets('History mechanic condivide repaint tra gruppo e pulsanti', (
    tester,
  ) async {
    final repository = _Repository(vehicles: const [vehicle]);
    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const MechanicWorkLogLaunch(vehicle: vehicle),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    final backButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-mechanic-back')),
    );
    final notificationsButton = tester.widget<AmSoftButton>(
      find.byKey(const Key('work-log-mechanic-notifications')),
    );
    final group = tester.widget<OCLiquidGlassGroup>(
      find.byKey(const Key('work-log-history-glass-group')),
    );

    expect(
      backButton.liquidGlassRepaint,
      same(notificationsButton.liquidGlassRepaint),
    );
    expect(group.repaint, same(backButton.liquidGlassRepaint));
    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);

    var repaintNotifications = 0;
    var maxScale = 1.0;
    backButton.liquidGlassRepaint!.addListener(() {
      repaintNotifications++;
      final scale = backButton.liquidGlassRepaint!.scale;
      if (scale > maxScale) maxScale = scale;
    });
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('work-log-mechanic-back'))),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.cancel();
    await tester.pump();

    expect(repaintNotifications, greaterThan(0));
    expect(maxScale, greaterThan(1));
  });

  testWidgets('owner non ridisegna i controlli durante push e pop del wizard', (
    tester,
  ) async {
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

    await tester.tap(find.byKey(const Key('work-log-owner-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));

    expect(_softButton(tester, 'work-log-owner-add').routeAnimation, isNull);
    expect(_softButton(tester, 'work-log-wizard-back').routeAnimation, isNull);

    await tester.pump(const Duration(milliseconds: 210));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(_softButton(tester, 'work-log-owner-add').routeAnimation, isNull);
    expect(_softButton(tester, 'work-log-wizard-back').routeAnimation, isNull);
  });

  testWidgets('history e dettaglio non ridisegnano i controlli nelle route', (
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
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    await tester.tap(find.byType(WorkLogItemCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));

    expect(_softButton(tester, 'work-log-owner-add').routeAnimation, isNull);
    expect(_softButton(tester, 'work-log-detail-back').routeAnimation, isNull);

    await tester.pump(const Duration(milliseconds: 210));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(_softButton(tester, 'work-log-owner-add').routeAnimation, isNull);
    expect(_softButton(tester, 'work-log-detail-back').routeAnimation, isNull);
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

  testWidgets('dal dettaglio aggiungi apre il wizard con lo stesso enum', (
    tester,
  ) async {
    final repository = _Repository(
      vehicles: const [vehicle],
      entries: [
        WorkLogEntry(
          id: 'work-distribution',
          vehicleId: vehicle.id,
          type: 'distribuzione',
          serviceKm: 30000,
          serviceDate: DateTime(2026, 8, 12),
          intervalKm: 60000,
        ),
      ],
    );
    await tester.pumpWidget(
      _app(
        WorkLogFeature(
          launch: const OwnerWorkLogLaunch(),
          dependencies: WorkLogDependencies(repository: repository),
        ),
      ),
    );
    await _pumpFeature(tester);

    await tester.tap(find.byType(WorkLogItemCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('work-log-detail-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final selector = tester.widget<WorkLogTypeSelectionGrid>(
      find.byType(WorkLogTypeSelectionGrid),
    );
    expect(selector.selectedType, WorkLogType.distribution.wireValue);
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

  testWidgets('i filtri restano fissi 125 pixel sotto la app bar', (
    tester,
  ) async {
    final repository = _Repository(
      vehicles: const [vehicle],
      entries: _entries(20, vehicle.id),
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
    expect(spacing.height, 185);

    final filters = find.byKey(const Key('work-log-history-filters'));
    final initialTop = tester.getTopLeft(filters).dy;
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(tester.getTopLeft(filters).dy, initialTop);

    final filterEdge = tester.widget<SmartEdge>(
      find.ancestor(of: filters, matching: find.byType(SmartEdge)).first,
    );
    expect(filterEdge.opacity, 0.2);
    expect(filterEdge.edges.map((edge) => edge.type), [
      EdgeType.leftEdge,
      EdgeType.rightEdge,
    ]);
    expect(filterEdge.edges.every((edge) => edge.size == 10), isTrue);
    expect(
      filterEdge.edges.every(
        (edge) =>
            edge.controlPoints.first.position == 0.2 &&
            edge.controlPoints.last.position == 1,
      ),
      isTrue,
    );
  });
}

Widget _app(Widget home) => MaterialApp(theme: AmTheme.dark, home: home);

Future<void> _pumpFeature(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

AmSoftButton _softButton(WidgetTester tester, String key) =>
    tester.widget<AmSoftButton>(find.byKey(Key(key), skipOffstage: false));

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
