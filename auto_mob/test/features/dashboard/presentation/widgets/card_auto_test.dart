import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/card_auto.dart';
import 'package:common_ui_widget/common_ui_widget.dart' show AmPullDownLG;
import 'package:figma_squircle/figma_squircle.dart';
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
    expect(find.textContaining('Aggiornati'), findsNothing);
    expect(find.byKey(const Key('km-last-update-label')), findsNothing);
    expect(find.text('+ 1.643 km'), findsOneWidget);
    expect(find.textContaining('Stimati:'), findsNothing);
    final cardSurface = tester.widget<Container>(
      find.byKey(const Key('vehicle-card-surface')),
    );
    final cardDecoration = cardSurface.decoration! as ShapeDecoration;
    expect(cardDecoration.shadows, [
      BoxShadow(
        color: AmThemeColors.light.shadowSoft,
        blurRadius: 2,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: AmThemeColors.light.shadow,
        blurRadius: 4,
        offset: const Offset(0, 4),
      ),
    ]);
    expect(
      (cardDecoration.gradient! as LinearGradient).colors,
      AmThemeColors.light.cardBorderGradient.colors,
    );
    final cardGradient = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(const Key('vehicle-card-surface')),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.gradient)
        .whereType<LinearGradient>()
        .first;
    expect(cardGradient.colors, [
      AmThemeColors.light.cardGradientStart,
      AmThemeColors.light.cardGradientEnd,
    ]);
    final yearBadge = tester.widget<Container>(
      find.byKey(const Key('vehicle-year-badge')),
    );
    expect(
      (yearBadge.decoration! as ShapeDecoration).color,
      AmThemeColors.light.surfaceRaised,
    );
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
    expect(updateButtonShape, isA<SmoothRectangleBorder>());
    expect(updateButtonShape.toString(), contains('cornerRadius: 20.00'));
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
    expect(_revisionBorderColor(tester), revisionColors.accent);
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
      expect(revisionIcon.color, revisionColors.danger);
      expect(_revisionStatusColor(tester), revisionColors.danger);
      expect(_revisionBorderColor(tester), revisionColors.danger);
    },
  );

  testWidgets('senza revisione mostra un avviso senza inventare una data', (
    tester,
  ) async {
    await _pumpCard(tester, revisionUnavailable: true);

    expect(find.textContaining('Da impostare'), findsOneWidget);
    expect(find.textContaining('scadenza non disponibile'), findsOneWidget);
    final colors = AmThemeColors.of(
      tester.element(find.byKey(const Key('revision-status-label'))),
    );
    expect(_revisionStatusColor(tester), colors.danger);
  });

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

  testWidgets('il trigger edit non mantiene un liquid glass nella card', (
    tester,
  ) async {
    await _pumpCard(tester);

    final editPull = tester.widget<AmPullDownLG>(find.byType(AmPullDownLG));
    expect(editPull.liquidGlassEnabled, isFalse);
    expect(editPull.popupLiquidGlassEnabled, isTrue);
  });
}

Color? _revisionBorderColor(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(
      of: find.byKey(const Key('revision-info-tile')),
      matching: find.byType(Ink),
    ),
  );
  final decoration = ink.decoration! as ShapeDecoration;
  final shape = decoration.shape as SmoothRectangleBorder;
  return shape.side.color;
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
  bool revisionUnavailable = false,
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
            nextRevisionDate: revisionUnavailable
                ? null
                : nextRevisionDate ?? DateTime(2027, 4, 17),
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
