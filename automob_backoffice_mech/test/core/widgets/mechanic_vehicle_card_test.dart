import 'package:automob_backoffice_mech/core/widgets/mechanic_shapes.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_card.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_work_badge.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in [AmTheme.dark, AmTheme.light]) {
    testWidgets(
      'la card veicolo chiusa mostra cerchio, veicolo, targa e ricavo',
      (tester) async {
        tester.view.physicalSize = const Size(380, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: MechanicVehicleCard(
                  vehicle: MechanicVehicleCardData(
                    id: 'vehicle-1',
                    name: 'Alfa Romeo Giulia',
                    plate: 'EF 456 GH',
                    year: 2021,
                    kilometers: 45500,
                    status: MechanicVehicleStatus.pending,
                    estimatedRevenueEuro: 150,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('ALFA ROMEO GIULIA'), findsOneWidget);
        expect(find.text('EF 456 GH'), findsOneWidget);
        expect(find.text('150€'), findsOneWidget);
        expect(find.text('Lavori da fare'), findsOneWidget);
        final circle = find.byKey(const Key('mechanic-vehicle-status-circle'));
        final circleSize = tester.getSize(circle);
        expect(circleSize.width, circleSize.height);
        expect(
          (tester.widget<DecoratedBox>(circle).decoration as BoxDecoration)
              .shape,
          BoxShape.circle,
        );
        final badgeRect = tester.getRect(find.byType(MechanicVehicleWorkBadge));
        final modelRect = tester.getRect(find.text('ALFA ROMEO GIULIA'));
        final plateRect = tester.getRect(
          find.byKey(const Key('mechanic-vehicle-plate')),
        );
        final revenueRect = tester.getRect(
          find.byKey(const Key('mechanic-vehicle-estimated-revenue')),
        );
        expect(badgeRect.left, lessThan(plateRect.left));
        expect(plateRect.bottom, lessThan(modelRect.top));
        expect(modelRect.right, lessThanOrEqualTo(revenueRect.left));

        final plate = tester.widget<DecoratedBox>(
          find.byKey(const Key('mechanic-vehicle-plate')),
        );
        expect(
          (plate.decoration as ShapeDecoration).color,
          theme.extension<AmThemeColors>()!.surfaceRaised,
        );
        expect(mechanicCornerSmoothing, 0.6);
        expect(
          tester
              .widgetList<Material>(find.byType(Material))
              .any((material) => material.shape is SmoothRectangleBorder),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'il pannello si chiude al tap e il pulsante storico apre il veicolo',
    (tester) async {
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var historyOpens = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: MechanicVehicleCard(
                onPressed: () => historyOpens++,
                vehicle: const MechanicVehicleCardData(
                  id: 'vehicle-2',
                  name: 'Fiat Panda',
                  plate: 'AB 123 CD',
                  year: 2022,
                  kilometers: 124000,
                  status: MechanicVehicleStatus.attention,
                  estimatedRevenueEuro: 150,
                  mandatoryWorks: [
                    MechanicMandatoryWorkItemData(
                      title: 'Tagliando periodico',
                      subtitle: 'Scadenza 120.000 km · 124.000 km attuali',
                    ),
                  ],
                  userProblems: [
                    MechanicUserProblemItemData(
                      id: 'rep-1',
                      description: 'rumore porta destra',
                      headerLabel: '26 OTT 2026  ·  km non rilevati',
                      warningLights: [
                        AmWarningLightData(
                          code: 'S10',
                          color: 'amber',
                          flashing: false,
                          description: 'rumore porta destra',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('2 lavori da fare'), findsOneWidget);
      final closedHeight = tester
          .getSize(find.byType(MechanicVehicleCard))
          .height;

      await tester.tap(find.text('FIAT PANDA'));
      await tester.pumpAndSettle();

      final openHeight = tester
          .getSize(find.byType(MechanicVehicleCard))
          .height;
      expect(openHeight, greaterThan(closedHeight));

      expect(find.text('SCADENZE OBBLIGATORIE'), findsOneWidget);
      expect(find.text('Tagliando periodico'), findsOneWidget);
      expect(
        find.byKey(const Key('mechanic-vehicle-works-divider')),
        findsOneWidget,
      );
      expect(find.text('SEGNALAZIONI UTENTE'), findsOneWidget);
      expect(find.text('Avaria motore'), findsOneWidget);
      expect(find.text('rumore porta destra'), findsOneWidget);
      expect(find.text('Segna come risolta'), findsNothing);

      final warningLightRect = tester.getRect(find.byType(AmWarningLight));
      final problemTitleRect = tester.getRect(find.text('Avaria motore'));
      expect(warningLightRect.right, lessThan(problemTitleRect.left));

      await tester.tap(find.text('Apri storico lavori'));
      await tester.pumpAndSettle();
      expect(historyOpens, 1);
      expect(
        tester.getSize(find.byType(MechanicVehicleCard)).height,
        openHeight,
      );

      await tester.tap(find.text('rumore porta destra'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(MechanicVehicleCard)).height,
        moreOrLessEquals(closedHeight),
      );

      await tester.tap(find.text('FIAT PANDA'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AmWarningLight));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(MechanicVehicleCard)).height,
        moreOrLessEquals(closedHeight),
      );
      expect(historyOpens, 1);
    },
  );
}
