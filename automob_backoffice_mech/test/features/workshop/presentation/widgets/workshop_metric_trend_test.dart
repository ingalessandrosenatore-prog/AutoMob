import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_metric_trend.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (value, label, icon) in [
    (12, '12 % in più', Icons.north_east_rounded),
    (-12, '12 % in meno', Icons.south_east_rounded),
    (0, '0 % invariato', Icons.east_rounded),
  ]) {
    testWidgets('variation $value follows its sign', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: WorkshopMetricTrend(value: value, isPercentage: true),
          ),
        ),
      );
      expect(find.textContaining(label, findRichText: true), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(icon)).color,
        AmThemeColors.dark.accent,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
