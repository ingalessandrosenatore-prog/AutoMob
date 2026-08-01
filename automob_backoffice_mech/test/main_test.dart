import 'package:automob_backoffice_mech/main.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the mechanic app boots with router and shared theme', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.routerConfig, isNotNull);
    expect(
      app.theme?.extension<AmThemeColors>()?.accent,
      const Color(0xFFFF6B00),
    );
  });
}
