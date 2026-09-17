import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  testWidgets('usa lo stesso percorso blur diretto del pull down', (
    tester,
  ) async {
    final animation = AnimationController(vsync: const TestVSync(), value: 0.5);
    addTearDown(animation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmSoftButton(
            width: 48,
            height: 48,
            color: Colors.orange,
            icon: HugeIcons.strokeRoundedAdd01,
            routeAnimation: animation,
          ),
        ),
      ),
    );

    final transition = find.byType(AmRouteBlurTransition);
    final transitionWidget = tester.widget<AmRouteBlurTransition>(transition);

    expect(transitionWidget.child, isNot(isA<RepaintBoundary>()));
    expect(
      find.descendant(of: transition, matching: find.byType(OCLiquidGlass)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: transition, matching: find.byType(CustomPaint)),
      findsWidgets,
    );
  });

  testWidgets('mantiene spring glow aptica e callback del bottone owner', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmSoftButton(
            width: 48,
            height: 48,
            color: Colors.orange,
            icon: HugeIcons.strokeRoundedAdd01,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    final gesture = find.byType(GestureDetector);
    final center = tester.getCenter(gesture);
    final pointer = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    final pressedScales = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((widget) => widget.transform.getMaxScaleOnAxis());
    expect(pressedScales.any((scale) => scale > 1), isTrue);

    await pointer.up();
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('supporta fallback piatto e IconData', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AmSoftButton(
            width: 140,
            height: 48,
            color: Colors.blue,
            icon: Icons.close,
            label: 'Chiudi',
            liquidGlassEnabled: false,
          ),
        ),
      ),
    );

    expect(find.byType(AmFlatGlass), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('Chiudi'), findsOneWidget);
  });

  testWidgets('inoltra lo spessore icona ricevuto dal chiamante', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmSoftButton(
            width: 48,
            height: 48,
            icon: HugeIcons.strokeRoundedAdd01,
            iconWeight: 3.1,
          ),
        ),
      ),
    );

    expect(tester.widget<HugeIcon>(find.byType(HugeIcon)).strokeWidth, 3.1);
  });

  testWidgets('applica il gradiente ricevuto solo quando richiesto', (
    tester,
  ) async {
    const gradient = LinearGradient(colors: [Colors.orange, Colors.red]);

    Widget app({required bool isGradient}) => MaterialApp(
      home: Center(
        child: AmSoftButton(
          width: 48,
          height: 48,
          icon: Icons.add,
          liquidGlassEnabled: false,
          iSgradient: isGradient,
          gradient: gradient,
        ),
      ),
    );

    Finder customGradient() => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient == gradient,
    );

    await tester.pumpWidget(app(isGradient: false));
    expect(customGradient(), findsNothing);

    await tester.pumpWidget(app(isGradient: true));
    expect(customGradient(), findsOneWidget);
    final gradientClip = tester.widget<ClipRRect>(
      find
          .ancestor(of: customGradient(), matching: find.byType(ClipRRect))
          .first,
    );
    expect(gradientClip.borderRadius, BorderRadius.circular(24));
  });

  testWidgets('inoltra il BoxShadow al liquid glass solo quando richiesto', (
    tester,
  ) async {
    const configuredShadow = BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      spreadRadius: 1,
      offset: Offset(0, 4),
    );

    Widget app({required bool shadow}) => MaterialApp(
      home: Center(
        child: AmSoftButton(
          width: 48,
          height: 48,
          icon: Icons.mic,
          shadow: shadow,
          boxShadow: configuredShadow,
        ),
      ),
    );

    await tester.pumpWidget(app(shadow: false));
    expect(tester.widget<OCLiquidGlass>(find.byType(OCLiquidGlass)).shadow, isNull);

    await tester.pumpWidget(app(shadow: true));
    expect(
      tester.widget<OCLiquidGlass>(find.byType(OCLiquidGlass)).shadow,
      configuredShadow,
    );
  });

  testWidgets('la pressione mantenuta si assesta senza crescere nel tempo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmSoftButton(
            width: 48,
            height: 48,
            icon: HugeIcons.strokeRoundedAdd01,
            onPressed: () {},
          ),
        ),
      ),
    );
    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(GestureDetector)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final maxScale = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((widget) => widget.transform.getMaxScaleOnAxis())
        .reduce(math.max);
    expect(maxScale, closeTo(1.08, 0.01));

    await pointer.up();
  });

  testWidgets('inoltra la scala al repaint del gruppo esterno', (tester) async {
    final repaint = AmLiquidGlassRepaintController();
    addTearDown(repaint.dispose);
    var repaintCount = 0;
    var maxRepaintScale = 1.0;
    repaint.addListener(() {
      repaintCount++;
      maxRepaintScale = math.max(maxRepaintScale, repaint.scale);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OCLiquidGlassGroup(
          repaint: repaint,
          settings: const OCLiquidGlassSettings(),
          child: Center(
            child: AmSoftButton(
              width: 48,
              height: 48,
              icon: HugeIcons.strokeRoundedAdd01,
              liquidGlassRepaint: repaint,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(GestureDetector)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OCLiquidGlassGroup), findsOneWidget);
    expect(repaintCount, greaterThan(0));
    expect(maxRepaintScale, greaterThan(1));

    await pointer.cancel();
  });
}
