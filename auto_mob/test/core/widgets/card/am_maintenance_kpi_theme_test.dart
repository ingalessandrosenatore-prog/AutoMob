import 'package:auto_mob_v1/core/router/shell_scaffold.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/core/widgets/card/kpi_service.dart';
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

  testWidgets('la card KPI usa il gradiente semantico in entrambi i temi', (
    tester,
  ) async {
    for (final theme in [AmTheme.light, AmTheme.dark]) {
      await pumpKpi(tester, theme);
      final colors = theme.extension<AmThemeColors>()!;
      final surface = tester.widget<Container>(
        find.byKey(const Key('am-maintenance-kpi-surface')),
      );
      final decoration = surface.decoration!;
      final gradient =
          (decoration is ShapeDecoration
                  ? decoration.gradient
                  : (decoration as BoxDecoration).gradient)!
              as LinearGradient;
      final isDark = theme.brightness == Brightness.dark;

      expect(
        gradient.colors,
        isDark
            ? [colors.surfaceHighlight, colors.surfaceDeep]
            : [colors.surfaceDeep, colors.surfaceHighlight],
      );
      expect(gradient.colors.first, isNot(gradient.colors.last));
      expect(
        tester.widget<ShaderMask>(find.byType(ShaderMask)).blendMode,
        BlendMode.srcIn,
      );
    }
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
