import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_card.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_shapes.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_work_badge.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in [AmTheme.dark, AmTheme.light]) {
    testWidgets('la card veicolo si adatta al tema e agli schermi stretti', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 180,
                child: MechanicVehicleCard(
                  vehicle: MechanicVehicleCardData(
                    id: 'vehicle-1',
                    name: 'Alfa Romeo Giulia',
                    plate: 'EF 456 GH',
                    year: 2021,
                    kilometers: 45500,
                    status: MechanicVehicleStatus.pending,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ALFA ROMEO GIULIA'), findsOneWidget);
      expect(find.text('EF 456 GH'), findsOneWidget);
      expect(find.text('2021'), findsNothing);
      expect(find.text('45.500 KM'), findsNothing);
      expect(find.text('Lavori da fare'), findsOneWidget);
      final circle = find.byKey(const Key('mechanic-vehicle-status-circle'));
      final circleSize = tester.getSize(circle);
      expect(circleSize.width, circleSize.height);
      expect(
        (tester.widget<DecoratedBox>(circle).decoration as BoxDecoration).shape,
        BoxShape.circle,
      );
      final cardSize = tester.getSize(find.byType(MechanicVehicleCard));
      expect(cardSize.height, lessThan(cardSize.width));
      final modelRect = tester.getRect(find.text('ALFA ROMEO GIULIA'));
      final badgeRect = tester.getRect(find.byType(MechanicVehicleWorkBadge));
      final plateRect = tester.getRect(
        find.byKey(const Key('mechanic-vehicle-plate')),
      );
      expect(plateRect.width, lessThan(cardSize.width - 16));
      expect(modelRect.bottom, lessThan(badgeRect.top));
      expect(badgeRect.bottom, lessThan(plateRect.top));
      expect(
        badgeRect.top - modelRect.bottom,
        moreOrLessEquals(plateRect.top - badgeRect.bottom),
      );
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
    });
  }
}
