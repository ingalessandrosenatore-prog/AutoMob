import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_card.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in [AmTheme.light, AmTheme.dark]) {
    testWidgets('gradiente, bordo e ombra della Home seguono il tema', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: MechanicVehicleCard(
              vehicle: MechanicVehicleCardData(
                id: 'vehicle-1',
                name: 'Alfa Romeo Giulia',
                plate: 'EF456GH',
                year: 2021,
                kilometers: 45500,
              ),
            ),
          ),
        ),
      );

      final card = find.byKey(const Key('mechanic-vehicle-card-corner-border'));
      final colors = theme.extension<AmThemeColors>()!;
      final decoration = tester.widget<DecoratedBox>(card).decoration;
      expect(decoration, isA<ShapeDecoration>());
      expect(
        (decoration as ShapeDecoration).gradient,
        colors.cardBorderGradient,
      );
      expect(decoration.shadows, colors.cardShadows);
      final borderInset = tester.widget<Padding>(
        find.descendant(of: card, matching: find.byType(Padding)).first,
      );
      expect(borderInset.padding, const EdgeInsets.all(1.5));
      expect(
        tester
            .widgetList<Material>(find.byType(Material))
            .any((material) => material.color == colors.surface),
        isTrue,
      );
      final statusIcon = find.byKey(const Key('mechanic-vehicle-status-icon'));
      expect(statusIcon, findsOneWidget);
      expect(find.text('0 lavori da fare'), findsOneWidget);
      expect(tester.widget<Icon>(statusIcon).icon, Icons.check_rounded);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('gli stati non connessi mostrano soltanto il warning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: const Scaffold(
          body: MechanicVehicleCard(
            vehicle: MechanicVehicleCardData(
              id: 'vehicle-2',
              name: 'Fiat Panda',
              plate: 'AB123CD',
              year: 2022,
              kilometers: 18000,
              status: MechanicVehicleStatus.service,
            ),
          ),
        ),
      ),
    );

    final statusIcon = tester.widget<Icon>(
      find.byKey(const Key('mechanic-vehicle-status-icon')),
    );
    expect(statusIcon.icon, Icons.warning_amber_rounded);
    expect(find.byType(Container), findsNothing);
  });
}
