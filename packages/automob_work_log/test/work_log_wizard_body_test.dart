import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  testWidgets('precompila nome e note e mantiene il report nel salvataggio', (
    tester,
  ) async {
    final repository = _Repository(
      reportsByVehicle: const {
        'vehicle-1': [
          WorkLogReport(
            id: 'report-1',
            description: 'Spia dopo l’avvio',
            warningLightCodes: ['S10'],
          ),
        ],
      },
    );
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(repository),
      getOpenReports: GetOpenWorkLogReports(repository),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _wizardApp(
        cubit: cubit,
        launch: const WorkLogLaunchContext(
          vehicleId: 'vehicle-1',
          vehicleName: 'Auto',
          currentKm: 1000,
          initialCustomName: 'Avaria motore',
          initialNotes: 'Controllare motore',
          sourceReportId: 'report-1',
        ),
      ),
    );
    expect(cubit.state.type, 'altro');
    await tester.scrollUntilVisible(
      find.byKey(const Key('work-log-custom-name')),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('work-log-data-step')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Avaria motore'), findsOneWidget);
    expect(cubit.state.notes, 'Controllare motore');
    await cubit.submit();
    expect(repository.saved?.customName, 'Avaria motore');
    expect(
      repository.saved?.notes,
      'Controllare motore\nProblemi risolti: Spia spenta: Avaria motore - Spia dopo l’avvio',
    );
    expect(repository.saved?.resolvedReportIds, ['report-1']);
    expect(cubit.state.status, WorkLogEditorStatus.success);
    // Reusing an editor for a normal work must clear the source report.
    cubit.initialize(
      const WorkLogLaunchContext(
        vehicleId: 'v2',
        vehicleName: 'Auto',
        currentKm: 0,
      ),
    );
    cubit.changeCustomName('Controllo');
    await tester.pump();
    await cubit.submit();
    expect(repository.saved?.resolvedReportIds, isEmpty);
  });

  testWidgets('seleziona le segnalazioni nei dati e aggiorna le note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository(
      reportsByVehicle: const {
        'vehicle-1': [
          WorkLogReport(
            id: 'engine',
            description: 'rumore porta destra',
            warningLightCodes: ['STOP'],
          ),
          WorkLogReport(id: 'noise', description: 'spia motore accesa'),
        ],
      },
    );
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(repository),
      getOpenReports: GetOpenWorkLogReports(repository),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(_wizardApp(cubit: cubit));
    cubit.changeType('batteria');
    await tester.pumpAndSettle();

    final engine = find.byKey(const Key('work-log-report-engine'));
    final noise = find.byKey(const Key('work-log-report-noise'));
    final notes = find.descendant(
      of: find.byKey(const Key('work-log-notes')),
      matching: find.byType(TextField),
    );
    final controller = tester.widget<TextField>(notes).controller!;
    expect(cubit.state.step, 0);
    expect(tester.widget<CheckboxListTile>(engine).value, isFalse);
    expect(tester.widget<CheckboxListTile>(noise).value, isFalse);
    await tester.tap(engine);
    await tester.pump();
    await tester.tap(noise);
    await tester.pump();
    expect(
      controller.text,
      'Problemi risolti: Spia spenta: Avvertenza generale - rumore porta destra\nspia motore accesa',
    );

    await tester.showKeyboard(notes);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Nota manuale',
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    await tester.pump();
    expect(cubit.state.notes, 'Nota manuale');
    await tester.tap(engine);
    await tester.pump();
    expect(
      controller.text,
      'Nota manuale\nProblemi risolti: spia motore accesa',
    );
    await tester.tap(noise);
    await tester.pump();
    expect(controller.text, 'Nota manuale');
    expect(cubit.state.composedNotes, 'Nota manuale');
    await tester.tap(noise);
    await tester.pump();
    await tester.tap(find.byKey(const Key('work-log-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('work-log-next')));
    await tester.pumpAndSettle();
    expect(cubit.state.step, 2);
    expect(noise, findsNothing);
    await tester.tap(find.byKey(const Key('work-log-next')));
    await tester.pumpAndSettle();
    expect(repository.saved?.resolvedReportIds, ['noise']);
    expect(
      repository.saved?.notes,
      'Nota manuale\nProblemi risolti: spia motore accesa',
    );
  });

  testWidgets('mantiene la UI originale e salva il ricambio', (tester) async {
    final repository = _Repository();
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(repository),
      getOpenReports: GetOpenWorkLogReports(repository),
    );
    WorkLogSaveResult? savedResult;

    await tester.pumpWidget(
      _wizardApp(cubit: cubit, onSaved: (result) => savedResult = result),
    );

    expect(find.byType(AmWizardProgress), findsOneWidget);
    expect(find.byType(AmEdgeBlur), findsNothing);

    await tester.tap(find.byKey(const Key('work-log-next')));
    await tester.pumpAndSettle();
    expect(cubit.state.step, 1);
    expect(find.byKey(const Key('work-log-parts-grid')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('work-log-parts-search')),
      'Candele',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('work-log-part-7')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('work-log-next')));
    await tester.pumpAndSettle();
    expect(cubit.state.step, 2);
    expect(find.byType(WorkLogSparePartCard), findsOneWidget);

    await tester.tap(find.text('Candele'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('part-price-7')), '12,50');
    await tester.tap(find.byKey(const Key('work-log-next')));
    await tester.pumpAndSettle();

    expect(find.text('Lavoro registrato'), findsOneWidget);
    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();

    expect(savedResult?.vehicleId, 'vehicle-1');
    expect(repository.saved?.parts.single.partId, 7);
    expect(repository.saved?.parts.single.unitPrice, 12.5);
    await cubit.close();
  });

  testWidgets('distingue un errore dal veicolo senza segnalazioni', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository()..reportsError = 'Errore di connessione';
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(repository),
      getOpenReports: GetOpenWorkLogReports(repository),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(_wizardApp(cubit: cubit));
    await tester.pumpAndSettle();

    final empty = find.text('Nessuna segnalazione aperta per questo veicolo');
    expect(find.text('Errore di connessione'), findsOneWidget);
    expect(empty, findsNothing);

    repository.reportsError = null;
    await tester.tap(find.text('Ricarica segnalazioni'));
    await tester.pumpAndSettle();
    expect(find.text('Errore di connessione'), findsNothing);
    expect(empty, findsOneWidget);
  });

  testWidgets('la tastiera non sposta la barra inferiore', (tester) async {
    final repository = _Repository();
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(repository),
      getOpenReports: GetOpenWorkLogReports(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_wizardApp(cubit: cubit, keyboardInset: 0));
    final button = find.byKey(const Key('work-log-next'));
    final bottomWithoutKeyboard = tester.getBottomRight(button).dy;

    final notesField = find.descendant(
      of: find.byKey(const Key('work-log-notes')),
      matching: find.byType(TextField),
    );
    await tester.scrollUntilVisible(
      notesField,
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('work-log-data-step')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.showKeyboard(notesField);
    await tester.pump();
    await tester.pumpWidget(_wizardApp(cubit: cubit, keyboardInset: 300));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.getBottomRight(button).dy, bottomWithoutKeyboard);
    expect(tester.takeException(), isNull);
    tester.testTextInput.hide();
    await tester.pump();
  });

  testWidgets('mostra i tipi aggiuntivi e il nome opzionale', (tester) async {
    tester.view.physicalSize = const Size(393, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository();
    final cubit = WorkLogEditorCubit(
      createWorkLog: CreateWorkLog(repository),
      getOpenReports: GetOpenWorkLogReports(repository),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_wizardApp(cubit: cubit));

    expect(find.text('Motore'), findsOneWidget);
    expect(find.text('Freni'), findsOneWidget);
    expect(find.text('Telaio'), findsOneWidget);
    expect(find.text('Elettronica'), findsOneWidget);
    expect(find.text('Batteria'), findsOneWidget);
    expect(find.text('Cambio'), findsOneWidget);
    expect(
      find.byKey(const Key('work-log-type-selection-grid')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'work-log-type-card-',
            ),
      ),
      findsNWidgets(12),
    );
    final grid = tester.widget<GridView>(
      find.byKey(const Key('work-log-type-selection-grid')),
    );
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      3,
    );
    expect(find.byKey(const Key('work-log-custom-name')), findsNothing);

    final brakesCard = find.byKey(const ValueKey('work-log-type-card-freni'));
    await tester.tap(brakesCard);
    await tester.pump();
    await tester.drag(
      find.byKey(const PageStorageKey('work-log-data-step')),
      const Offset(0, -420),
    );
    await tester.pump();

    expect(cubit.state.type, 'freni');
    expect(find.byKey(const Key('work-log-custom-name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _wizardApp({
  required WorkLogEditorCubit cubit,
  double keyboardInset = 0,
  WorkLogLaunchContext? launch,
  ValueChanged<WorkLogSaveResult>? onSaved,
}) => MaterialApp(
  theme: AmTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: true,
      viewInsets: EdgeInsets.only(bottom: keyboardInset),
    ),
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      body: WorkLogWizardBody(
        context:
            launch ??
            const WorkLogLaunchContext(
              vehicleId: 'vehicle-1',
              vehicleName: 'Alfa Romeo Giulia',
              currentKm: 1000,
              initialWorkType: 'tagliando',
            ),
        cubit: cubit,
        onSaved: onSaved ?? (_) {},
      ),
    ),
  ),
);

class _Repository implements WorkLogRepository {
  _Repository({this.reportsByVehicle = const {}});

  final Map<String, List<WorkLogReport>> reportsByVehicle;
  String? reportsError;

  @override
  Future<Either<String, List<WorkLogReport>>> getOpenReports(
    String vehicleId,
  ) async {
    final error = reportsError;
    if (error != null) return left(error);
    return right(reportsByVehicle[vehicleId] ?? const []);
  }

  WorkLogDraft? saved;

  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) async {
    saved = draft;
    return right(unit);
  }

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async => right(const []);

  @override
  Future<Either<String, List<WorkLogVehicle>>> getVehicles() async =>
      right(const []);
}
