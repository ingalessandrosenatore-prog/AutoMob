import 'package:auto_mob_v1/core/router/shell_scaffold.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/core/widgets/card/kpi_service.dart';
import 'package:common_ui_widget/common_ui_widget.dart'
    show AmRouteBlurTransition;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpKpi(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AmMaintenanceKpiCard(
            iconBuilder: _buildIcon,
            color: Color(0xFF3192F3),
            label: 'Tagliando',
            remainingKm: 10000,
            percentage: 75,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la card KPI usa surface e bordo da 1.5 in entrambi i temi', (
    tester,
  ) async {
    for (final theme in [AmTheme.light, AmTheme.dark]) {
      await pumpKpi(tester, theme);
      final colors = theme.extension<AmThemeColors>()!;
      final surface = tester.widget<Container>(
        find.byKey(const Key('am-maintenance-kpi-surface')),
      );
      expect(surface.padding, const EdgeInsets.all(1.5));
      final decoration = surface.decoration!;
      final borderGradient =
          (decoration as ShapeDecoration).gradient! as LinearGradient;
      expect(borderGradient, colors.cardBorderGradient);
      expect(borderGradient.begin, Alignment.topCenter);
      expect(borderGradient.end, Alignment.bottomCenter);
      final surfaceDecoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(const Key('am-maintenance-kpi-surface')),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .first;
      expect(surfaceDecoration.color, colors.surface);
      expect(surfaceDecoration.gradient, isNull);
      expect(
        tester.widget<ShaderMask>(find.byType(ShaderMask)).blendMode,
        BlendMode.srcIn,
      );
      expect(
        tester.getSize(
          find.byKey(const Key('maintenance-kpi-percentage-ring')),
        ),
        const Size.square(58),
      );
    }
  });

  testWidgets('la card KPI segue la route animation ricevuta', (tester) async {
    final animation = AnimationController(vsync: tester, value: .5);
    addTearDown(animation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: AmMaintenanceKpiCard(
            iconBuilder: _buildIcon,
            color: const Color(0xFF3192F3),
            label: 'Tagliando',
            remainingKm: 10000,
            percentage: 75,
            routeAnimation: animation,
          ),
        ),
      ),
    );

    expect(find.byType(AmRouteBlurTransition), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, lessThan(1));
  });

  testWidgets('la tab inattiva usa il testo secondario del tema chiaro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: const Scaffold(
          body: AmNavItem(
            icon: Icons.build_outlined,
            iconIsActive: Icons.build,
            lable: 'Lavori',
            isSelect: false,
            onTap: _noop,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, AmThemeColors.light.textSecondary);
    expect(icon.color, isNot(Colors.white));
  });
}

Widget _buildIcon(double size, Color color) =>
    Icon(Icons.handyman_outlined, size: size, color: color);

void _noop() {}
