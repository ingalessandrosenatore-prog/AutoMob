import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_vehicle_filter.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_search_controls.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  testWidgets('usa il glass quando non riceve un gradiente', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_app(controller: controller));

    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
    expect(find.byType(OCLiquidGlass), findsOneWidget);
    final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
    expect(
      searchBar.backgroundColor?.resolve(const {}),
      AmThemeColors.dark.surface,
    );
    expect(searchBar.elevation?.resolve(const {}), 0);
    expect(searchBar.shadowColor?.resolve(const {}), Colors.transparent);
    expect(searchBar.surfaceTintColor?.resolve(const {}), Colors.transparent);
    expect(searchBar.overlayColor?.resolve(const {}), Colors.transparent);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 1 && widget.height == 24,
      ),
      findsNothing,
    );
    final sharedFill = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('workshop-search-shared-fill')),
    );
    expect(sharedFill.color, AmThemeColors.dark.surface);
    final filter = tester.widget<AmPullDownLG>(find.byType(AmPullDownLG));
    expect(filter.circularTrigger, isFalse);
    expect(filter.transparentTrigger, isFalse);
    expect(
      find.byKey(const Key('am-pull-down-trigger-static-surface')),
      findsOneWidget,
    );
    final borderSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('workshop-search-border-surface')),
    );
    final borderDecoration = borderSurface.decoration as ShapeDecoration;
    expect(borderDecoration.gradient, AmThemeColors.dark.cardBorderGradient);
    expect(borderDecoration.shadows, AmThemeColors.dark.cardShadows);
  });

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
      AmThemeColors.light.surface,
    );
    final borderSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('workshop-search-border-surface')),
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
          filter: WorkshopVehicleFilter.all,
          onSearchChanged: (_) {},
          onFilterChanged: (_) {},
        ),
      ),
    );
