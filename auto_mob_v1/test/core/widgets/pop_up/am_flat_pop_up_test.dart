import 'package:auto_mob_v1/core/widgets/smart/am_flat_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('si adatta al contenuto e mantiene il colore di riempimento', (
    tester,
  ) async {
    const color = Color(0xFF0F0F11);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmFlatPopUp(
              color: color,
              borderRadius: BorderRadius.all(Radius.circular(24)),
              child: SizedBox(width: 180, height: 120),
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.descendant(
        of: find.byType(AmFlatPopUp),
        matching: find.byType(Container),
      ),
    );
    final decoration = surface.decoration! as BoxDecoration;

    expect(tester.getSize(find.byType(AmFlatPopUp)), const Size(180, 120));
    expect(decoration.color, color);
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(24)),
    );
  });
}
