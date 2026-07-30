import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/am_spare_part_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('espande e richiude i dettagli senza setState', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AmSparePartCard(
              item: const SelectedPart(partId: 15, quantity: 2),
              name: 'Filtro olio',
              onRemove: () {},
              onItemChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsNothing);

    await tester.tap(find.text('Filtro olio'));
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('Filtro olio'));
    await tester.pump();

    expect(find.byType(TextFormField), findsNothing);
  });
}
