import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

void main() {
  testWidgets('uses the lightweight edge gradients while blur is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: SmartEdge(
            blur: true,
            fallbackTint: AmTheme.light.scaffoldBackgroundColor,
            edges: [
              EdgeBlur(
                type: EdgeType.topEdge,
                size: 24,
                sigma: 4,
                tintColor: AmTheme.light.scaffoldBackgroundColor,
                controlPoints: [
                  ControlPoint(position: 0.5, type: ControlPointType.visible),
                  ControlPoint(position: 1, type: ControlPointType.transparent),
                ],
              ),
            ],
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );

    expect(find.byType(SoftEdgeBlur), findsNothing);
    final edge = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient is LinearGradient,
      ),
    );
    final gradient = (edge.decoration as BoxDecoration).gradient!;
    expect(
      gradient.colors.first,
      AmTheme.light.scaffoldBackgroundColor.withValues(alpha: 0.92),
    );
  });
}
