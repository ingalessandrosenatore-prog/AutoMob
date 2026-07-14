import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_mob_v1/core/ios_animation_claude/ios_animation_claude.dart';

void main() {
  Widget buildApp({LiquidZoomTarget? target}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LiquidZoom(
            target: target ??
                const LiquidZoomTarget.modal(width: 300, height: 400),
            destinationBuilder: (context, close) => Center(
              child: TextButton(
                onPressed: close,
                child: const Text('CHIUDI'),
              ),
            ),
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  group('LiquidZoom', () {
    testWidgets('il tap sul trigger apre la destinazione con il morph',
        (tester) async {
      await tester.pumpWidget(buildApp());
      expect(find.text('CHIUDI'), findsNothing);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('CHIUDI'), findsOneWidget);
    });

    testWidgets('il callback close richiude la route fino a smontarla',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CHIUDI'));
      await tester.pumpAndSettle();

      expect(find.text('CHIUDI'), findsNothing);
      // Il trigger deve essere di nuovo interattivo (morph tornato a 0).
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('CHIUDI'), findsOneWidget);
    });

    testWidgets('il tap sullo scrim fuori dalla card chiude la route',
        (tester) async {
      await tester.pumpWidget(buildApp(
        target: const LiquidZoomTarget.modal(width: 200, height: 200),
      ));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('CHIUDI'), findsOneWidget);

      // Angolo in alto a sinistra: sicuramente fuori dalla card 200x200.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('CHIUDI'), findsNothing);
    });
  });
}
