import 'package:automob_work_log/src/presentation/work_log_history_edge.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:common_ui_widget/performance_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('history usa gli edge della Home con gli stessi valori', (
    tester,
  ) async {
    const background = Color(0xFF0F0F11);

    await tester.pumpWidget(
      const MaterialApp(
        home: WorkLogHistoryEdge(
          backgroundColor: background,
          accentColor: Color(0xFFFF6B00),
          child: SizedBox.expand(key: Key('history')),
        ),
      ),
    );

    final smartEdge = tester.widget<SmartEdge>(find.byType(SmartEdge));
    expect(smartEdge.blur, kHeavyEffects);
    expect(smartEdge.opacity, 0.96);
    expect(smartEdge.fallbackTint, background);
    expect(smartEdge.edges, hasLength(2));

    final top = smartEdge.edges[0];
    expect(top.type, EdgeType.topEdge);
    expect(top.size, 120);
    expect(top.sigma, 10);
    expect(top.tintColor, background);

    final bottom = smartEdge.edges[1];
    expect(bottom.type, EdgeType.bottomEdge);
    expect(bottom.size, 92);
    expect(bottom.sigma, 10);
    expect(bottom.tintColor, background);

    for (final edge in smartEdge.edges) {
      expect(edge.controlPoints[0].position, 0.5);
      expect(edge.controlPoints[0].type, ControlPointType.visible);
      expect(edge.controlPoints[1].position, 1);
      expect(edge.controlPoints[1].type, ControlPointType.transparent);
    }
    expect(find.byKey(const Key('history')), findsOneWidget);
  });
}
