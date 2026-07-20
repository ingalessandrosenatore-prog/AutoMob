import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/work_log_part.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/work_log_row.dart';
import 'package:auto_mob_v1/features/work_log/presentation/pages/work_log_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkLogRow work({String? notes = 'Nota completa senza troncamenti'}) =>
      WorkLogRow(
        id: 'w1',
        type: 'tagliando',
        serviceKm: 42000,
        serviceDate: DateTime(2026, 7, 20),
        notes: notes,
        hasWorkshop: true,
        workshopName: 'Officina Ferrari',
        parts: const [
          WorkLogPart(
            partId: 1,
            name: 'Olio motore 5W30',
            quantity: 2,
            unitPriceCents: 1250,
          ),
          WorkLogPart(
            partId: 2,
            name: 'Filtro olio',
            quantity: 1,
            unitPriceCents: 1800,
          ),
        ],
      );

  Future<void> pumpPage(WidgetTester tester, WorkLogRow value) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: WorkLogDetailPage(work: value),
      ),
    );
  }

  testWidgets('mostra nota completa, officina, parti e totale ricambi', (
    tester,
  ) async {
    await pumpPage(tester, work());

    expect(find.text('DETTAGLIO INTERVENTO'), findsOneWidget);
    expect(find.text('Tagliando'), findsOneWidget);
    expect(find.text('20 Lug 2026 · 42.000 km'), findsOneWidget);
    expect(find.text('Officina Ferrari'), findsOneWidget);
    expect(find.byKey(const Key('work-log-detail-note')), findsOneWidget);
    expect(find.text('Nota completa senza troncamenti'), findsOneWidget);
    expect(find.text('Olio motore 5W30'), findsOneWidget);
    expect(find.text('2 × 12,50 €'), findsOneWidget);
    expect(find.text('25,00 €'), findsOneWidget);
    expect(find.byKey(const Key('work-log-parts-total')), findsOneWidget);
    expect(find.text('43,00 €'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mostra fallback per note e parti vuote senza officina', (
    tester,
  ) async {
    final value = WorkLogRow(
      id: 'w2',
      type: 'revisione',
      serviceKm: 50000,
      serviceDate: DateTime(2026, 7, 20),
      hasWorkshop: false,
    );

    await pumpPage(tester, value);

    expect(find.text('Tu'), findsOneWidget);
    expect(find.text('NOTE'), findsOneWidget);
    expect(find.text('Nessuna nota'), findsOneWidget);
    expect(find.text('PARTI SOSTITUITE'), findsOneWidget);
    expect(
      find.byKey(const Key('work-log-detail-empty-parts')),
      findsOneWidget,
    );
    expect(
      find.text('Non sono state registrate parti per questo intervento'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
