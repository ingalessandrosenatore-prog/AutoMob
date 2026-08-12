import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  testWidgets('mantiene la UI originale e salva il ricambio', (tester) async {
    final repository = _Repository();
    final cubit = WorkLogEditorCubit(createWorkLog: CreateWorkLog(repository));
    WorkLogSaveResult? savedResult;

    await tester.pumpWidget(
      _wizardApp(cubit: cubit, onSaved: (result) => savedResult = result),
    );

    expect(find.byType(AmWizardProgress), findsOneWidget);
    expect(find.byType(AmEdgeBlur), findsWidgets);

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

  testWidgets('la tastiera non sposta la barra inferiore', (tester) async {
    final repository = _Repository();
    final cubit = WorkLogEditorCubit(createWorkLog: CreateWorkLog(repository));
    addTearDown(cubit.close);

    await tester.pumpWidget(_wizardApp(cubit: cubit, keyboardInset: 0));
    final button = find.byKey(const Key('work-log-next'));
    final bottomWithoutKeyboard = tester.getBottomRight(button).dy;

    final notesField = find.descendant(
      of: find.byKey(const Key('work-log-notes')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(notesField);
    await tester.showKeyboard(notesField);
    await tester.pump();
    await tester.pumpWidget(_wizardApp(cubit: cubit, keyboardInset: 300));
    await tester.pump(const Duration(milliseconds: 320));

    expect(tester.getBottomRight(button).dy, bottomWithoutKeyboard);
    expect(tester.takeException(), isNull);
    tester.testTextInput.hide();
    await tester.pump();
  });
}

Widget _wizardApp({
  required WorkLogEditorCubit cubit,
  double keyboardInset = 0,
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
        context: const WorkLogLaunchContext(
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
