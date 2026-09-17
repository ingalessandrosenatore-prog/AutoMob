import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('renderizza colore blur radius e HugeIcon configurabili', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SmallPrincipal(
              label: 'Play',
              color: const Color(0xFF2F73E8),
              icon: HugeIcons.strokeRoundedPlay,
              width: 112,
              height: 44,
              borderRadius: 18,
              blurRadius: 12,
              onPressed: () => presses++,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HugeIcon), findsOneWidget);
    expect(tester.widget<HugeIcon>(find.byType(HugeIcon)).size, 20);
    expect(
      tester.getSize(find.byKey(const Key('small-principal-gradient'))),
      const Size(112, 44),
    );
    expect(
      find.byKey(const Key('small-principal-backdrop-blur')),
      findsOneWidget,
    );
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('small-principal-gradient')),
    );
    final decoration = surface.decoration as ShapeDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(
      gradient.colors.first,
      Color.lerp(
        const Color(0xFF2F73E8),
        Colors.white,
        0.20,
      )!.withValues(alpha: 0.98),
    );
    expect(gradient.colors[1], const Color(0xFF2F73E8).withValues(alpha: 0.96));
    expect(gradient.colors[2], const Color(0xFF2F73E8).withValues(alpha: 0.96));
    expect(gradient.colors.last, gradient.colors.first);
    expect(gradient.stops, const [0, 0.05, 0.95, 1]);
    expect(
      (decoration.shape as SmoothRectangleBorder).side,
      const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.38), width: 0.5),
    );
    expect(
      (decoration.shape as SmoothRectangleBorder).borderRadius.toString(),
      contains('18.0'),
    );
    expect(
      find.byKey(const Key('small-principal-edge-treatment')),
      findsOneWidget,
    );
    final outerSurface = tester.widget<DecoratedBox>(
      find.byKey(const Key('small-principal-shadow')),
    );
    expect((outerSurface.decoration as ShapeDecoration).shadows, isEmpty);
    final inkWell = tester.widget<InkWell>(
      find.byKey(const Key('small-principal-tap-target')),
    );
    expect(
      inkWell.overlayColor!.resolve({WidgetState.pressed}),
      Colors.white.withValues(alpha: 0.12),
    );

    await tester.tap(find.byKey(const Key('small-principal-tap-target')));
    expect(presses, 1);
  });

  testWidgets('supporta testo senza icona e stato disabilitato', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SmallPrincipal(
              label: 'Cancel',
              color: Color(0xFF505762),
              onPressed: null,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HugeIcon), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.48);
    expect(
      tester
          .widget<InkWell>(find.byKey(const Key('small-principal-tap-target')))
          .onTap,
      isNull,
    );
  });

  testWidgets('mostra il caricamento e blocca il tap', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SmallPrincipal(
          label: 'Accedi',
          color: Colors.blue,
          isLoading: true,
          onPressed: () => presses++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Accedi'), findsNothing);
    await tester.tap(find.byKey(const Key('small-principal-tap-target')));
    expect(presses, 0);
  });

  testWidgets('con la sola HugeIcon diventa circolare 46 per 46', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SmallPrincipal(
            color: Colors.blue,
            icon: HugeIcons.strokeRoundedTick02,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Text), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('small-principal-gradient'))),
      const Size.square(46),
    );
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('small-principal-gradient')),
    );
    expect(
      (surface.decoration as ShapeDecoration).shape.toString(),
      contains('23.0'),
    );
  });
}
