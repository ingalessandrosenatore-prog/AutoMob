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
    expect(cardSurface.decoration, isNull);
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
      AmThemeColors.light.surfaceHighlight.withValues(alpha: 0.6),
      AmThemeColors.light.surfaceHighlight.withValues(alpha: 0.7),
      AmThemeColors.light.surfaceHighlight.withValues(alpha: 0.9),
      AmThemeColors.light.surfaceHighlight,
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
    expect(find.text('AGGIORNA'), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('vehicle-current-km')))
          .style
          ?.fontSize,
      17,
    );
    expect(tester.widget<Text>(find.text('+ 1.643 km')).style?.fontSize, 10);
    expect(
      tester.getSize(find.byKey(const Key('mileage-info-tile'))).height,
      60,
    );
    final mileageColors = AmThemeColors.of(
      tester.element(find.byKey(const Key('mileage-status-icon'))),
    );
    final mileageIcon = tester.widget<HugeIcon>(
      find.byKey(const Key('mileage-status-icon')),
    );
    final mileageWatermark = tester.widget<HugeIcon>(
      find.byKey(const Key('mileage-watermark-icon')),
    );
    expect(mileageIcon.icon, HugeIcons.strokeRoundedDashboardSpeed02);
    expect(mileageIcon.color, mileageColors.accent);
    expect(mileageWatermark.icon, HugeIcons.strokeRoundedDashboardSpeed02);
    expect(
      mileageWatermark.color,
      mileageColors.accent.withValues(alpha: 0.08),
    );
    expect(
      _mileageFillColor(tester),
      mileageColors.accent.withValues(alpha: 0.045),
    );
    expect(_mileageBorderColor(tester), mileageColors.accent);
    expect(find.byType(IconButton), findsNothing);
    final addIcon = tester.widget<HugeIcon>(
      find.byKey(const Key('update-km-button')),
    );
    expect(addIcon.icon, HugeIcons.strokeRoundedAdd01);
    expect(addIcon.color, mileageColors.accent);
    final mileageCenterY = tester
        .getCenter(find.byKey(const Key('mileage-info-tile')))
        .dy;
    for (final key in [
      const Key('mileage-status-icon'),
      const Key('vehicle-current-km'),
      const Key('km-estimated-increment'),
      const Key('update-km-button'),
    ]) {
      expect(
        tester.getCenter(find.byKey(key)).dy,
        closeTo(mileageCenterY, 0.5),
      );
    }
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

Color? _mileageFillColor(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(
      of: find.byKey(const Key('mileage-info-tile')),
      matching: find.byType(Ink),
    ),
  );
  return (ink.decoration! as ShapeDecoration).color;
}

Color? _mileageBorderColor(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(
      of: find.byKey(const Key('mileage-info-tile')),
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
  tester.view.physicalSize = const Size(390, 1000);
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
