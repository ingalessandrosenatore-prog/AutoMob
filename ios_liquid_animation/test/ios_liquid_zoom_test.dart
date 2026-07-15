import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ios_liquid_animation/ios_liquid_animation.dart';

void main() {
  group('IosLiquidZoom', () {
    testWidgets('apre la destinazione e torna al trigger con il risultato', (
      tester,
    ) async {
      final controller = IosLiquidZoomController<int>();
      const sourceKey = Key('source');
      const destinationKey = Key('destination');
      const closeKey = Key('close');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IosLiquidZoom<int>(
                controller: controller,
                layout: const IosLiquidModalLayout(
                  width: 280,
                  height: 240,
                  respectSafeArea: false,
                ),
                config: const IosLiquidZoomConfig(
                  transitionDuration: Duration(milliseconds: 220),
                  reverseTransitionDuration: Duration(milliseconds: 180),
                  liftDuration: Duration(milliseconds: 80),
                  liftLeadDuration: Duration(milliseconds: 10),
                  backgroundBlur: 0,
                ),
                sourceBuilder: (context, zoom) => FilledButton(
                  key: sourceKey,
                  onPressed: () {
                    zoom.open();
                  },
                  child: const Text('Apri'),
                ),
                destinationBuilder: (context, zoom) => ColoredBox(
                  key: destinationKey,
                  color: Colors.white,
                  child: Center(
                    child: TextButton(
                      key: closeKey,
                      onPressed: () {
                        zoom.close(7);
                      },
                      child: const Text('Chiudi'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(sourceKey), findsOneWidget);
      expect(find.byKey(destinationKey), findsNothing);
      expect(controller.phase, IosLiquidZoomPhase.idle);

      final result = controller.open();
      await tester.pump();
      expect(controller.phase, IosLiquidZoomPhase.lifting);

      await tester.pumpAndSettle();
      expect(find.byKey(destinationKey), findsOneWidget);
      expect(controller.phase, IosLiquidZoomPhase.open);

      unawaited(controller.close(7));
      await tester.pump();
      expect(controller.phase, IosLiquidZoomPhase.closing);

      await tester.pumpAndSettle();
      expect(find.byKey(destinationKey), findsNothing);
      expect(find.byKey(sourceKey), findsOneWidget);
      expect(controller.phase, IosLiquidZoomPhase.idle);
      expect(await result, 7);
    });

    testWidgets('il tap fuori dal modale avvia la chiusura', (tester) async {
      final controller = IosLiquidZoomController<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: IosLiquidZoomTap<void>(
                controller: controller,
                source: const SizedBox(
                  key: Key('tap-source'),
                  width: 80,
                  height: 40,
                ),
                destination: const ColoredBox(
                  key: Key('tap-destination'),
                  color: Colors.white,
                ),
                layout: const IosLiquidModalLayout(
                  width: 240,
                  height: 180,
                  respectSafeArea: false,
                ),
                config: const IosLiquidZoomConfig(
                  transitionDuration: Duration(milliseconds: 120),
                  reverseTransitionDuration: Duration(milliseconds: 100),
                  liftDuration: Duration(milliseconds: 60),
                  liftLeadDuration: Duration.zero,
                  captureSource: false,
                  backgroundBlur: 0,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(40, 20));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tap-destination')), findsOneWidget);

      await tester.tapAt(const Offset(790, 20));
      await tester.pump();
      expect(controller.phase, IosLiquidZoomPhase.closing);

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tap-destination')), findsNothing);
    });
  });

  group('IosLiquidZoomLayout', () {
    test('pagina e modale risolvono rettangoli prevedibili', () {
      const viewport = Size(400, 800);
      const safeArea = EdgeInsets.only(top: 24, bottom: 16);
      const source = Rect.fromLTWH(300, 700, 48, 48);

      final page = const IosLiquidPageLayout(
        respectSafeArea: true,
      ).resolve(viewport: viewport, safeArea: safeArea, sourceRect: source);
      final modal = const IosLiquidModalLayout(
        width: 320,
        height: 300,
      ).resolve(viewport: viewport, safeArea: safeArea, sourceRect: source);

      expect(page, const Rect.fromLTRB(0, 24, 400, 784));
      expect(modal.width, 320);
      expect(modal.height, 300);
      expect(modal.bottom, 768);
    });

    test('il popup resta dentro i margini dello schermo', () {
      final rect = const IosLiquidPopupLayout(size: Size(220, 180)).resolve(
        viewport: const Size(320, 640),
        safeArea: EdgeInsets.zero,
        sourceRect: const Rect.fromLTWH(290, 600, 24, 24),
      );

      expect(rect.left, 92);
      expect(rect.right, 312);
      expect(rect.top, 452);
      expect(rect.bottom, 632);
    });
  });
}
