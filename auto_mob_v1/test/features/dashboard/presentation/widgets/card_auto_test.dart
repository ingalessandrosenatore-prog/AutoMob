import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/card_auto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('mostra targa, km, stima e revisione dentro la card', (
    tester,
  ) async {
    await _pumpCard(tester);

    expect(find.text('ALFA ROMEO STELVIO'), findsOneWidget);
    expect(find.text('AB123CD'), findsOneWidget);
    expect(find.text('166.600 km'), findsOneWidget);
    expect(find.text('CHILOMETRAGGIO'), findsNothing);
    expect(find.text('Aggiornati 18 giorni fa'), findsOneWidget);
    expect(find.text('Stimati: 1.643 km'), findsOneWidget);
    expect(find.text('Regolare · scade 17/04/2027'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('ALFA ROMEO STELVIO')).style?.fontSize,
      16,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('vehicle-current-km')))
          .style
          ?.fontSize,
      22,
    );
    expect(
      tester.getSize(find.byKey(const Key('update-km-button'))).height,
      40,
    );
    final updateButton = tester.widget<FilledButton>(
      find.byKey(const Key('update-km-button')),
    );
    final updateButtonShape = updateButton.style?.shape?.resolve({});
    expect(updateButtonShape, isA<RoundedRectangleBorder>());
    expect(
      (updateButtonShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(22),
    );
    expect(
      tester.getSize(find.byKey(const Key('revision-info-tile'))).height,
      60,
    );
    final revisionIconFinder = find.byKey(const Key('revision-status-icon'));
    final revisionColors = AmThemeColors.of(tester.element(revisionIconFinder));
    final revisionIcon = tester.widget<HugeIcon>(revisionIconFinder);
    expect(revisionIcon.icon, HugeIcons.strokeRoundedCalendar01);
    expect(revisionIcon.color, revisionColors.accent);
    expect(_revisionStatusColor(tester), revisionColors.accent);
  });

  testWidgets(
    'mantiene il calendario arancione e colora in rosso la scadenza',
    (tester) async {
      await _pumpCard(tester, nextRevisionDate: DateTime(2026, 8, 10));

      expect(find.text('In scadenza · scade 10/08/2026'), findsOneWidget);
      final revisionIconFinder = find.byKey(const Key('revision-status-icon'));
      final revisionColors = AmThemeColors.of(
        tester.element(revisionIconFinder),
      );
      final revisionIcon = tester.widget<HugeIcon>(revisionIconFinder);
      expect(revisionIcon.icon, HugeIcons.strokeRoundedCalendar01);
      expect(revisionIcon.color, revisionColors.accent);
      expect(_revisionStatusColor(tester), revisionColors.danger);
    },
  );

  testWidgets('i comandi km e revisione restano interattivi', (tester) async {
    var kmTaps = 0;
    var revisionTaps = 0;
    await _pumpCard(
      tester,
      onKmTap: () => kmTaps++,
      onRevisionTap: () => revisionTaps++,
    );

    await tester.tap(find.byKey(const Key('update-km-button')));
    await tester.tap(find.byKey(const Key('revision-info-tile')));

    expect(kmTaps, 1);
    expect(revisionTaps, 1);
  });
}

Color? _revisionStatusColor(WidgetTester tester) {
  final label = tester.widget<Text>(
    find.byKey(const Key('revision-status-label')),
  );
  final rootSpan = label.textSpan! as TextSpan;
  return (rootSpan.children!.first as TextSpan).style?.color;
}

Future<void> _pumpCard(
  WidgetTester tester, {
  VoidCallback? onKmTap,
  VoidCallback? onRevisionTap,
  DateTime? nextRevisionDate,
}) async {
  tester.view.physicalSize = const Size(500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AmTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CardAuto(
            marca: 'Alfa Romeo',
            modello: 'Stelvio',
            kmTotali: '166600 km',
            targa: 'AB123CD',
            anno: 2021,
            kmUpdatedAt: DateTime.utc(2026, 7, 2, 12),
            daysSinceKmUpdate: 18,
            estimatedAdditionalKm: 1643,
            nextRevisionDate: nextRevisionDate ?? DateTime(2027, 4, 17),
            referenceDate: DateTime(2026, 7, 20),
            onKmTap: onKmTap,
            onRevisionTap: onRevisionTap,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
