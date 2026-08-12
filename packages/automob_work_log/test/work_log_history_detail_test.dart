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
    expect(find.text('Tagliando'), findsOneWidget);
    await tester.tap(find.text('Tagliando'));
    expect(selected, entry);
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
    expect(find.text('Tagliando'), findsOneWidget);
  });

  testWidgets('il dettaglio mostra note, ricambi e totale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(body: WorkLogDetailBody(entry: entry)),
      ),
    );

    expect(find.text('Controllo completo'), findsOneWidget);
    expect(find.text('Candele'), findsOneWidget);
    expect(find.text('25.00 €'), findsNWidgets(2));
  });
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
