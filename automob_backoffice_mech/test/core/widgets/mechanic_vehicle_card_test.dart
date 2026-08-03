import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_card.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_shapes.dart';
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
              padding: EdgeInsets.all(12),
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
      );

      expect(find.text('Alfa Romeo Giulia'), findsOneWidget);
      expect(find.text('EF 456 GH'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);
      expect(find.text('45.500 KM'), findsOneWidget);
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
