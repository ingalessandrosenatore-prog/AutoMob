import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa i gradienti anche quando il blur e richiesto', (
    tester,
  ) async {
    const tint = Color(0xFF101114);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartEdge(
          blur: true,
          opacity: 0.96,
          fallbackTint: tint,
          edges: [
            EdgeBlur(
              type: EdgeType.topEdge,
              size: 72,
              tintColor: tint,
              sigma: 10,
              controlPoints: [
                ControlPoint(position: 0.5, type: ControlPointType.visible),
                ControlPoint(position: 1, type: ControlPointType.transparent),
              ],
            ),
            EdgeBlur(
              type: EdgeType.bottomEdge,
              size: 92,
              tintColor: tint,
              sigma: 10,
              controlPoints: [
                ControlPoint(position: 0.5, type: ControlPointType.visible),
                ControlPoint(position: 1, type: ControlPointType.transparent),
              ],
            ),
          ],
          child: const SizedBox.expand(key: Key('content')),
        ),
      ),
    );

    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(find.byType(SoftEdgeBlur), findsNothing);
    expect(find.byType(DecoratedBox), findsNWidgets(2));
    final positioned = tester.widgetList<Positioned>(find.byType(Positioned));
    expect(
      positioned.any((widget) => widget.top == 0 && widget.height == 72),
      isTrue,
    );
    expect(
      positioned.any((widget) => widget.bottom == 0 && widget.height == 92),
      isTrue,
    );
  });
}
