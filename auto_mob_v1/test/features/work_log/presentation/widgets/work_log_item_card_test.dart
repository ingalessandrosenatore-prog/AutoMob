import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/work_log_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la card compatta espone il tap sull’intero intervento', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: WorkLogItemCard(
            title: 'Tagliando',
            date: '20 Lug 2026',
            km: '42.000 km',
            description: 'Nota del lavoro',
            hasWorkshop: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
    expect(find.text('Officina'), findsOneWidget);
  });
}
