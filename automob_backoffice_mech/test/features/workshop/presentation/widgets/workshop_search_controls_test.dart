import 'package:automob_backoffice_mech/core/router/mechanic_shell_metrics.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_search_controls.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  testWidgets(
    'usa il glass con altezza ridotta e non mostra il pulsante filtro',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_app(controller: controller));

      expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
      expect(find.byType(OCLiquidGlass), findsOneWidget);
      expect(MechanicShellMetrics.searchHeight, 42);
      expect(
        tester.getSize(find.byType(WorkshopSearchControls)).height,
        MechanicShellMetrics.searchHeight,
      );
      final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
      expect(searchBar.backgroundColor?.resolve(const {}), Colors.transparent);
      expect(searchBar.elevation?.resolve(const {}), 0);
      expect(searchBar.shadowColor?.resolve(const {}), Colors.transparent);
      expect(searchBar.surfaceTintColor?.resolve(const {}), Colors.transparent);
      expect(searchBar.overlayColor?.resolve(const {}), Colors.transparent);
      expect(find.byType(AmPullDownLG), findsNothing);
      expect(
        find.byKey(const ValueKey('workshop_filter_button')),
        findsNothing,
      );
      expect(find.byTooltip('Filtra veicoli'), findsNothing);
      final sharedFill = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mechanic-search-shared-fill')),
      );
      final sharedDecoration = sharedFill.decoration as BoxDecoration;
      expect(
        sharedDecoration.color,
        AmThemeColors.dark.surface.withValues(alpha: 0.72),
      );
      expect(
        tester
            .widget<OCLiquidGlassGroup>(find.byType(OCLiquidGlassGroup))
            .settings
            .blurRadiusPx,
        8,
      );
      final borderSurface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('mechanic-search-border-surface')),
      );
      final borderDecoration = borderSurface.decoration as ShapeDecoration;
      expect(borderDecoration.gradient, AmThemeColors.dark.cardBorderGradient);
      expect(borderDecoration.shadows, AmThemeColors.dark.cardShadows);
    },
  );

  testWidgets('in light usa surface e il bordo illuminato del tema', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller: controller, theme: AmTheme.light));

    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
    expect(find.byType(OCLiquidGlass), findsOneWidget);
    expect(
      tester
          .widget<SearchBar>(find.byType(SearchBar))
          .backgroundColor
          ?.resolve(const {}),
      Colors.transparent,
    );
    final borderSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('mechanic-search-border-surface')),
    );
    final decoration = borderSurface.decoration as ShapeDecoration;
    expect(decoration.gradient, AmThemeColors.light.cardBorderGradient);
    expect(
      (decoration.gradient! as LinearGradient).colors.first,
      const Color(0xFFFFFFFF),
    );
  });
}

Widget _app({required TextEditingController controller, ThemeData? theme}) =>
    MaterialApp(
      theme: theme ?? AmTheme.dark,
      home: Scaffold(
        body: WorkshopSearchControls(
          enabled: true,
          controller: controller,
          onSearchChanged: (_) {},
        ),
      ),
    );
