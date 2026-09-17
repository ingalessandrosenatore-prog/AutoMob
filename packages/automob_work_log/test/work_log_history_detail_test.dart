import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  final entry = WorkLogEntry(
    id: 'work-1',
    vehicleId: 'vehicle-1',
    type: 'tagliando',
    serviceKm: 42000,
    serviceDate: DateTime(2026, 8, 8),
    notes: 'Controllo completo',
    parts: const [
      WorkLogPart(
        partId: 7,
        name: 'Candele',
        quantity: 2,
        unitPriceCents: 1250,
      ),
    ],
  );

  testWidgets('lo storico carica il veicolo e apre il lavoro selezionato', (
    tester,
  ) async {
    final repository = _Repository(entries: [entry]);
    final bloc = WorkLogHistoryBloc(
      getVehicleWorkHistory: GetVehicleWorkHistory(repository),
    );
    addTearDown(bloc.close);
    WorkLogEntry? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkLogHistoryBody(
            context: const WorkLogLaunchContext(
              vehicleId: 'vehicle-1',
              vehicleName: 'Alfa Romeo Giulia',
              currentKm: 42000,
            ),
            bloc: bloc,
            onEntryPressed: (entry) => selected = entry,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.requestedVehicleId, 'vehicle-1');
    expect(find.byKey(const Key('work-log-item-work-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-log-item-work-1')));
    expect(selected, entry);
  });

  testWidgets('i choice chip filtrano lo storico per tipo', (tester) async {
    final brakeEntry = WorkLogEntry(
      id: 'work-brakes',
      vehicleId: 'vehicle-1',
      type: 'freni',
      customName: 'Pastiglie',
      serviceKm: 43000,
      serviceDate: DateTime(2026, 8, 9),
    );
    final repository = _Repository(entries: [entry, brakeEntry]);
    final bloc = WorkLogHistoryBloc(
      getVehicleWorkHistory: GetVehicleWorkHistory(repository),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: WorkLogHistoryBody(
            context: const WorkLogLaunchContext(
              vehicleId: 'vehicle-1',
              vehicleName: 'Alfa Romeo Giulia',
              currentKm: 43000,
            ),
            bloc: bloc,
            onEntryPressed: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tagliando'), findsNWidgets(2));
    expect(find.text('Pastiglie'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('work-log-history-filters')),
      const Offset(-1000, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-log-history-filter-freni')));
    await tester.pump();

    expect(find.text('Pastiglie'), findsOneWidget);
    expect(find.byKey(const Key('work-log-item-work-1')), findsNothing);
    final selectedChip = tester.widget<ChoiceChip>(
      find.byKey(const Key('work-log-history-filter-freni')),
    );
    expect(selectedChip.selected, isTrue);
    expect(selectedChip.labelStyle?.color, AmThemeColors.light.accent);
    expect(
      (selectedChip.side! as BorderSide).color,
      AmThemeColors.light.accent,
    );
  });

  testWidgets('un rebuild dopo il ritorno non riapre il caricamento', (
    tester,
  ) async {
    final repository = _Repository(entries: [entry]);
    final bloc = WorkLogHistoryBloc(
      getVehicleWorkHistory: GetVehicleWorkHistory(repository),
    );
    addTearDown(bloc.close);
    const context = WorkLogLaunchContext(
      vehicleId: 'vehicle-1',
      vehicleName: 'Alfa Romeo Giulia',
      currentKm: 42000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkLogHistoryBody(
            context: context,
            bloc: bloc,
            onEntryPressed: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkLogHistoryBody(
            context: context,
            bloc: bloc,
            onEntryPressed: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('work-log-item-work-1')), findsOneWidget);
  });

  testWidgets('il dettaglio mostra ricambi e totale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(body: WorkLogDetailBody(entry: entry)),
      ),
    );

    expect(find.text('Candele'), findsOneWidget);
    expect(find.text('25.00 €'), findsNWidgets(2));
    final table = tester.widget<DecoratedBox>(
      find.byKey(const Key('work-log-detail-parts-table-surface')),
    );
    expect(
      (table.decoration as BoxDecoration).color,
      AmThemeColors.dark.surface,
    );
  });

  testWidgets('il nuovo dettaglio usa immagine, scadenza e tabella ricambi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scheduledEntry = WorkLogEntry(
      id: 'work-2',
      vehicleId: 'vehicle-1',
      type: 'distribuzione',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 8, 8),
      intervalKm: 60000,
      parts: entry.parts,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: WorkLogDetailPage(entry: scheduledEntry, currentKm: 50000),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DISTRIBUZIONE'), findsOneWidget);
    expect(find.byKey(const Key('work-log-detail-back')), findsOneWidget);
    expect(find.text('Regolare'), findsOneWidget);
    expect(find.text('52.000 KM'), findsNWidgets(2));
    expect(find.text('60.000 KM'), findsOneWidget);
    expect(find.text('Candele'), findsOneWidget);
    expect(find.text('25.00 €'), findsNWidgets(2));
    final hero = tester.widget<Image>(
      find.byKey(const Key('work-log-detail-hero')),
    );
    expect(
      (hero.image as AssetImage).assetName,
      'assets/images/motor_check.png',
    );
  });

  testWidgets('il dettaglio anima foto contatore e tacche in sincronia', (
    tester,
  ) async {
    final scheduledEntry = WorkLogEntry(
      id: 'work-animation',
      vehicleId: 'vehicle-1',
      type: 'tagliando',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 8, 8),
      intervalKm: 15000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: WorkLogDetailPage(entry: scheduledEntry, currentKm: 50000),
      ),
    );

    final initialPhoto = tester.widget<SlideTransition>(
      find.byKey(const Key('work-log-detail-photo-entrance')),
    );
    expect(initialPhoto.position.value.dx, greaterThan(0));
    expect(find.text('0 KM'), findsNWidgets(2));
    expect(_activeProgressMarks(tester), 0);

    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('0 KM'), findsNothing);
    expect(_activeProgressMarks(tester), greaterThan(0));

    await tester.pumpAndSettle();
    expect(find.text('7.000 KM'), findsNWidgets(2));
    expect(_activeProgressMarks(tester), 2);
    final finalPhoto = tester.widget<SlideTransition>(
      find.byKey(const Key('work-log-detail-photo-entrance')),
    );
    expect(finalPhoto.position.value.dx, closeTo(0, 0.001));
  });

  testWidgets('il pulsante dettaglio usa il tipo intervento in ingresso', (
    tester,
  ) async {
    WorkLogType? requestedType;
    final scheduledEntry = WorkLogEntry(
      id: 'work-action',
      vehicleId: 'vehicle-1',
      type: 'distribuzione',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 8, 8),
      intervalKm: 60000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: WorkLogDetailPage(
          entry: scheduledEntry,
          currentKm: 50000,
          onAddPressed: (type) => requestedType = type,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AGGIUNGI DISTRIBUZIONE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('work-log-detail-add')));
    expect(requestedType, WorkLogType.distribution);
  });

  testWidgets('il dettaglio sfuma info nel background dall angolo destro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: WorkLogDetailPage(entry: entry),
      ),
    );

    final background = tester.widget<DecoratedBox>(
      find.byKey(const Key('work-log-detail-background')),
    );
    final gradient = (background.decoration as BoxDecoration).gradient;

    expect(gradient, isA<RadialGradient>());
    final radialGradient = gradient! as RadialGradient;
    expect(radialGradient.center, Alignment.topRight);
    expect(radialGradient.colors.last, AmThemeColors.dark.background);
    expect(radialGradient.colors.first, isNot(AmThemeColors.dark.background));
    expect(
      radialGradient.colors.first.b,
      greaterThan(AmThemeColors.dark.background.b),
    );
  });

  testWidgets('senza intervallo mostra trattini e non mostra lo stato', (
    tester,
  ) async {
    final unscheduledEntry = WorkLogEntry(
      id: 'work-3',
      vehicleId: 'vehicle-1',
      type: 'altro',
      customName: 'Lucidatura',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 8, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkLogDetailBody(entry: unscheduledEntry, currentKm: 50000),
        ),
      ),
    );

    expect(find.text('Regolare'), findsNothing);
    expect(find.text('Scaduto'), findsNothing);
    expect(find.text('-'), findsNWidgets(3));
    final hero = tester.widget<Image>(
      find.byKey(const Key('work-log-detail-hero')),
    );
    expect((hero.image as AssetImage).assetName, 'assets/images/car_check.png');
  });

  testWidgets('rotazione gomme usa le gomme e mostra scaduto', (tester) async {
    final tiresEntry = WorkLogEntry(
      id: 'work-4',
      vehicleId: 'vehicle-1',
      type: 'pneumatici_inversione',
      serviceKm: 42000,
      serviceDate: DateTime(2026, 8, 8),
      intervalKm: 10000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkLogDetailBody(entry: tiresEntry, currentKm: 53000),
        ),
      ),
    );

    expect(find.text('Scaduto'), findsOneWidget);
    final hero = tester.widget<Image>(
      find.byKey(const Key('work-log-detail-hero')),
    );
    expect(
      (hero.image as AssetImage).assetName,
      'assets/images/gomme_check.png',
    );
  });

  testWidgets('i nuovi tipi usano le rispettive immagini', (tester) async {
    final cases = <String, String>{
      'freni': 'assets/images/brakes_check.png',
      'telaio': 'assets/images/chassis_check.png',
      'elettronica': 'assets/images/electronics_check.png',
      'batteria': 'assets/images/electronics_check.png',
      'cambio': 'assets/images/gearbox_check.png',
    };

    for (final entryCase in cases.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: WorkLogDetailBody(
              entry: WorkLogEntry(
                id: 'work-${entryCase.key}',
                vehicleId: 'vehicle-1',
                type: entryCase.key,
                serviceKm: 42000,
                serviceDate: DateTime(2026, 8, 8),
              ),
            ),
          ),
        ),
      );

      final hero = tester.widget<Image>(
        find.byKey(const Key('work-log-detail-hero')),
      );
      expect((hero.image as AssetImage).assetName, entryCase.value);
    }
  });

  test('il catalogo ricambi conserva i nomi e aggiunge le categorie', () {
    expect(kPartsCatalog[7], 'Candele');
    expect(kPartsCatalog[95], 'altro');
    expect(kWorkLogPartsCatalog[7]?.category, WorkLogPartCategory.engine);
    expect(kWorkLogPartsCatalog[20]?.category, WorkLogPartCategory.brakes);
    expect(kWorkLogPartsCatalog[28]?.category, WorkLogPartCategory.chassis);
    expect(kWorkLogPartsCatalog[53]?.category, WorkLogPartCategory.electronics);
    expect(kWorkLogPartsCatalog[86]?.category, WorkLogPartCategory.tires);
    for (var partId = 36; partId <= 43; partId++) {
      expect(
        kWorkLogPartsCatalog[partId]?.category,
        WorkLogPartCategory.gearbox,
      );
    }
    expect(kWorkLogPartsCatalog[44]?.category, WorkLogPartCategory.chassis);
  });
}

int _activeProgressMarks(WidgetTester tester) {
  final accent = AmThemeColors.dark.accent;
  return tester
      .widgetList<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'work-log-detail-progress-',
              ),
        ),
      )
      .where((mark) => (mark.decoration! as BoxDecoration).color == accent)
      .length;
}

class _Repository implements WorkLogRepository {
  _Repository({required this.entries});

  final List<WorkLogEntry> entries;
  String? requestedVehicleId;

  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) async =>
      right(unit);

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async {
    requestedVehicleId = vehicleId;
    return right(entries);
  }

  @override
  Future<Either<String, List<WorkLogVehicle>>> getVehicles() async =>
      right(const []);
}
