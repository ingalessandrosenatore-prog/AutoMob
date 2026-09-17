import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final testCase in <({ThemeData theme, bool paints})>[
    (theme: AmTheme.light, paints: true),
    (theme: AmTheme.dark, paints: false),
  ]) {
    testWidgets(
      'il bordo diagonale ${testCase.paints ? 'compare in light' : 'sparisce in dark'}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: testCase.theme,
            home: const Scaffold(
              body: AmDiagonalCornerBorder(
                key: Key('border'),
                radius: 30,
                child: SizedBox(width: 240, height: 120),
              ),
            ),
          ),
        );

        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const Key('border')),
            matching: find.byKey(const Key('am-diagonal-corner-border-paint')),
          ),
        );
        expect(paint.foregroundPainter, testCase.paints ? isNotNull : isNull);
      },
    );
  }
}
