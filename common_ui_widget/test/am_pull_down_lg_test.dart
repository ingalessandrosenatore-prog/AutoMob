import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  testWidgets('apre il menu e inoltra il tap della voce', (tester) async {
    var selections = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('vehicle-pull-down'),
              brand: '',
              lable: 'Veicolo',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              larghezza: 220,
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: true,
              liquidGlassEnabled: false,
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedCar05,
                  text: 'Alfa Romeo',
                  onTap: () => selections++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('vehicle-pull-down')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Alfa Romeo'), findsOneWidget);

    await tester.tap(find.text('Alfa Romeo'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(selections, 1);
    expect(find.text('Alfa Romeo'), findsNothing);
  });

  testWidgets(
    'usa una superficie statica anche quando era richiesto il glass',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AmPullDownLG(
                key: const Key('flat-trigger-glass-popup'),
                brand: '',
                lable: '',
                backgroundColor: Colors.black,
                popupBackgroundColor: Colors.black,
                onTap: () {},
                larghezza: 220,
                buttonIcons: HugeIcons.strokeRoundedEdit01,
                buttonIconsSize: 20,
                iconColor: Colors.white,
                textColor: Colors.white,
                buttonLableStyle: const TextStyle(),
                arrow: false,
                liquidGlassEnabled: false,
                popupLiquidGlassEnabled: true,
                children: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(OCLiquidGlassGroup), findsNothing);
      expect(find.byType(OCLiquidGlass), findsNothing);

      await tester.tap(find.byKey(const Key('flat-trigger-glass-popup')));
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(OCLiquidGlassGroup), findsNothing);
      expect(find.byType(OCLiquidGlass), findsNothing);
      expect(
        find.byKey(const Key('am-pull-down-popup-static-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('am-pull-down-popup-backdrop-blur')),
        findsOneWidget,
      );
    },
  );

  testWidgets('rispetta geometria e tipografia degli item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('item-metrics-pull-down'),
              brand: '',
              lable: 'Veicolo',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              larghezza: 220,
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: true,
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedCar05,
                  text: 'Alfa Romeo',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('item-metrics-pull-down')));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('am-pull-down-popup-row-0'));
    expect(tester.getSize(row).height, 52);
    final padding = tester.widget<Padding>(
      find.byKey(const Key('am-pull-down-item-padding')),
    );
    expect(padding.padding, const EdgeInsets.symmetric(horizontal: 20));
    final icon = tester.widget<HugeIcon>(
      find.descendant(of: row, matching: find.byType(HugeIcon)),
    );
    expect(icon.size, 20);
    final gaps = tester
        .widgetList<SizedBox>(
          find.descendant(of: row, matching: find.byType(SizedBox)),
        )
        .where((box) => box.width == 14);
    expect(gaps, hasLength(1));
    final text = tester.widget<Text>(find.text('Alfa Romeo'));
    expect(text.style?.fontSize, 16);
    expect(text.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('esegue la navigazione solo dopo avere rimosso il popup', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('navigation-pull-down'),
              brand: '',
              lable: '',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              larghezza: 220,
              buttonIcons: HugeIcons.strokeRoundedMoreHorizontalCircle02,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: false,
              liquidGlassEnabled: false,
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedSettings01,
                  text: 'Settings',
                  onTap: () {
                    navigatorKey.currentState!.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          key: Key('settings-route'),
                          body: Text('Impostazioni'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('navigation-pull-down')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.byKey(const Key('settings-route')), findsNothing);

    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();

    expect(find.byKey(const Key('settings-route')), findsOneWidget);
    expect(find.text('Settings'), findsNothing);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-route')), findsNothing);
    expect(find.text('Settings'), findsNothing);

    await tester.tap(find.byKey(const Key('navigation-pull-down')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('anima opacity e scala senza filtri nei due versi del morph', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('vehicle-pull-down'),
              brand: '',
              lable: 'Veicolo',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              larghezza: 220,
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: true,
              liquidGlassEnabled: false,
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedCar05,
                  text: 'Alfa Romeo',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Opacity buttonOpacity() => tester.widget<Opacity>(
      find.byKey(const Key('am-pull-down-morph-opacity')),
    );

    expect(find.byType(ImageFiltered), findsNothing);
    expect(buttonOpacity().opacity, 1);

    await tester.tap(find.byKey(const Key('vehicle-pull-down')));
    await tester.pump();
    expect(find.byType(ImageFiltered), findsNothing);

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(
      find.byKey(const Key('am-pull-down-popup-morph-light')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 180));
    expect(buttonOpacity().opacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 450));
    expect(buttonOpacity().opacity, closeTo(0, 0.001));

    await tester.tap(find.text('Alfa Romeo'));
    await tester.pump();
    expect(buttonOpacity().opacity, closeTo(0, 0.001));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(ImageFiltered), findsNothing);
    expect(buttonOpacity().opacity, greaterThan(0));
    expect(buttonOpacity().opacity, lessThan(1));

    await tester.pumpAndSettle();
    expect(find.text('Alfa Romeo'), findsNothing);
    expect(buttonOpacity().opacity, 1);
  });

  testWidgets('il morph del popup non introduce filtri offscreen', (
    tester,
  ) async {
    final controller = AnimationController.unbounded(
      vsync: const TestVSync(),
      value: 0.9,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MorphPopUp(
          rectButton: const Rect.fromLTWH(100, 100, 120, 48),
          larghezza: 220,
          ctrlm: controller,
          backgroundColor: Colors.black,
          liquidGlassEnabled: false,
          onClosing: () {},
          children: [
            ItemMorphPopUp(
              icon: HugeIcons.strokeRoundedCar05,
              text: 'Alfa Romeo',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsNothing);

    controller.value = 0.95;
    await tester.pump();
    expect(find.byType(ImageFiltered), findsNothing);

    controller.value = 1;
    await tester.pump();
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('ingrandisce la superficie e azzera la pressione in chiusura', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('vehicle-pull-down'),
              brand: '',
              lable: 'Veicolo',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              larghezza: 220,
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: true,
              liquidGlassEnabled: false,
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedCar05,
                  text: 'Alfa Romeo',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(const Key('vehicle-pull-down'));
    final initialSize = tester.getSize(trigger);
    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final surface = find.byKey(
      const Key('am-pull-down-trigger-static-surface'),
    );
    final surfaceScaleFinder = find.byKey(
      const Key('am-pull-down-press-surface-scale'),
    );
    Transform surfaceScale() => tester.widget<Transform>(surfaceScaleFinder);

    expect(
      find.descendant(of: surfaceScaleFinder, matching: surface),
      findsOneWidget,
    );
    expect(surfaceScale().transform.getMaxScaleOnAxis(), closeTo(1.15, 0.02));
    final buttonLight = tester.widget<CustomPaint>(
      find.byKey(const Key('am-pull-down-button-press-light')),
    );
    expect((buttonLight.painter! as GlowPainter).intensity, greaterThan(0));
    expect(tester.getSize(trigger), initialSize);

    await gesture.up();
    await tester.pump();
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();

    expect(surfaceScale().transform.getMaxScaleOnAxis(), closeTo(1, 0.001));

    await tester.pumpAndSettle();
  });

  testWidgets('ingrandisce anche l intera superficie statica', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('liquid-pull-down'),
              brand: '',
              lable: 'Veicolo',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: true,
              buttonShadow: const BoxShadow(
                color: Colors.black38,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedCar05,
                  text: 'Alfa Romeo',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(const Key('liquid-pull-down'));
    expect(find.byType(OCLiquidGlassGroup), findsNothing);
    expect(find.byType(OCLiquidGlass), findsNothing);
    final triggerSurface = tester.widget<DecoratedBox>(
      find.byKey(const Key('am-pull-down-trigger-decoration')),
    );
    final triggerDecoration = triggerSurface.decoration as ShapeDecoration;
    expect((triggerDecoration.gradient! as LinearGradient).colors, const [
      Color.fromRGBO(255, 255, 255, 0.782),
      Color.fromRGBO(250, 250, 252, 0.748),
      Color.fromRGBO(241, 241, 242, 0.714),
    ]);
    expect(
      (triggerDecoration.shape as SmoothRectangleBorder).side.color,
      const Color.fromRGBO(255, 255, 255, 0.72),
    );
    final triggerShadow = tester.widget<DecoratedBox>(
      find.byKey(const Key('am-pull-down-button-shadow')),
    );
    expect(
      (triggerShadow.decoration as ShapeDecoration).shadows!.single,
      const BoxShadow(
        color: Colors.black38,
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final surfaceScaleFinder = find.byKey(
      const Key('am-pull-down-press-surface-scale'),
    );
    final surfaceScale = tester.widget<Transform>(surfaceScaleFinder);
    expect(
      find.descendant(
        of: surfaceScaleFinder,
        matching: find.byKey(const Key('am-pull-down-trigger-static-surface')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: surfaceScaleFinder,
        matching: find.byKey(const Key('am-pull-down-trigger-backdrop-blur')),
      ),
      findsOneWidget,
    );
    expect(surfaceScale.transform.getMaxScaleOnAxis(), closeTo(1.15, 0.02));

    await gesture.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets('resta statico anche dentro un gruppo glass esterno', (
    tester,
  ) async {
    final repaint = AmLiquidGlassRepaintController();
    addTearDown(repaint.dispose);
    var repaintCount = 0;
    var maxRepaintScale = 1.0;
    repaint.addListener(() {
      repaintCount++;
      if (repaint.scale > maxRepaintScale) maxRepaintScale = repaint.scale;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OCLiquidGlassGroup(
          repaint: repaint,
          settings: const OCLiquidGlassSettings(),
          child: Center(
            child: AmPullDownLG(
              key: const Key('liquid-pull-down'),
              brand: '',
              lable: '',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: false,
              ownsLiquidGlassGroup: false,
              liquidGlassRepaint: repaint,
              children: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
    expect(find.byType(OCLiquidGlass), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('am-pull-down-press-surface-scale')),
        matching: find.byKey(const Key('am-pull-down-trigger-static-surface')),
      ),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('liquid-pull-down'))),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repaintCount, greaterThan(0));
    expect(maxRepaintScale, greaterThan(1));
    await gesture.cancel();
  });

  testWidgets('il popup usa il gradiente statico del tema', (tester) async {
    final controller = AnimationController.unbounded(
      vsync: const TestVSync(),
      value: 1,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MorphPopUp(
          rectButton: const Rect.fromLTWH(100, 100, 48, 48),
          larghezza: 220,
          ctrlm: controller,
          backgroundColor: Colors.black,
          onClosing: () {},
          children: const [],
        ),
      ),
    );

    expect(find.byType(OCLiquidGlassGroup), findsNothing);
    expect(find.byType(OCLiquidGlass), findsNothing);
    expect(
      find.byKey(const Key('am-pull-down-popup-decoration')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('am-pull-down-popup-surface')), findsOneWidget);
  });

  testWidgets('limita il radius alla meta del lato piu corto', (tester) async {
    final controller = AnimationController.unbounded(
      vsync: const TestVSync(),
      value: 1,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MorphPopUp(
          rectButton: const Rect.fromLTWH(100, 100, 48, 48),
          larghezza: 220,
          ctrlm: controller,
          backgroundColor: Colors.black,
          popupBorderRadius: 80,
          onClosing: () {},
          children: const [],
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('am-pull-down-popup-static-surface')),
    );
    final shape = (surface.decoration as ShapeDecoration).shape;
    expect(shape.toString(), contains('34.0'));
    expect(find.byKey(const Key('am-pull-down-popup-shadow')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('am-pull-down-popup-surface')))
          .height,
      68,
    );
  });

  testWidgets('usa popupHeight quando viene fornita', (tester) async {
    final controller = AnimationController.unbounded(
      vsync: const TestVSync(),
      value: 0.5,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MorphPopUp(
          rectButton: const Rect.fromLTWH(100, 100, 48, 48),
          larghezza: 220,
          popupHeight: 180,
          popupShadow: const BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          ctrlm: controller,
          backgroundColor: Colors.black,
          onClosing: () {},
          children: const [],
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const Key('am-pull-down-popup-surface')))
          .height,
      180,
    );
    final popupShadow = tester.widget<DecoratedBox>(
      find.byKey(const Key('am-pull-down-popup-shadow')),
    );
    expect(
      (popupShadow.decoration as ShapeDecoration).shadows!.single,
      const BoxShadow(
        color: Colors.black45,
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    );
  });

  testWidgets('il trigger circolare separa visuale e touch target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('circular-trigger'),
              brand: '',
              lable: '',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              buttonIcons: HugeIcons.strokeRoundedMoreHorizontalCircle02,
              buttonIconsSize: 21,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: false,
              circularTrigger: true,
              liquidGlassEnabled: false,
              children: const [],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('circular-trigger'))),
      const Size(44, 44),
    );
    expect(
      tester.getSize(
        find.byKey(const Key('am-pull-down-trigger-static-surface')),
      ),
      const Size(40, 40),
    );
  });
}
