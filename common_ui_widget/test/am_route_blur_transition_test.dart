import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('senza animation restituisce il child senza transizione', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AmRouteBlurTransition(
          child: SizedBox(key: Key('content'), width: 40, height: 40),
        ),
      ),
    );

    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(find.byType(AnimatedBuilder), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('animation controlla solo fade e attivazione del blur', (
    tester,
  ) async {
    final animation = AnimationController(vsync: const TestVSync(), value: 0);
    addTearDown(animation.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AmRouteBlurTransition(
          animation: animation,
          child: const SizedBox(key: Key('content'), width: 40, height: 40),
        ),
      ),
    );

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(find.byType(Transform), findsNothing);
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
      isTrue,
    );

    animation.value = 0.5;
    await tester.pump();

    expect(
      tester.widget<Opacity>(find.byType(Opacity)).opacity,
      closeTo(0.875, 0.001),
    );
    expect(find.byType(Transform), findsNothing);

    animation.value = 1;
    await tester.pump();

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(find.byType(Transform), findsNothing);
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
      isFalse,
    );

    animation.value = 0;
    await tester.pump();

    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(find.byType(Transform), findsNothing);
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
      isTrue,
    );
  });

  testWidgets('i due pulsanti accettano la stessa route animation', (
    tester,
  ) async {
    final animation = AnimationController(vsync: const TestVSync(), value: 0.5);
    addTearDown(animation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AmSoftButton(
                width: 48,
                height: 48,
                icon: Icons.close,
                routeAnimation: animation,
              ),
              AmPullDownLG(
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
                liquidGlassEnabled: false,
                routeAnimation: animation,
                children: const [],
              ),
            ],
          ),
        ),
      ),
    );

    final routeTransitions = find.byType(AmRouteBlurTransition);
    expect(routeTransitions, findsNWidgets(2));
    expect(
      find.descendant(
        of: routeTransitions,
        matching: find.byType(ImageFiltered),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('am-pull-down-button-morph-blur')),
      findsNothing,
    );
  });
}
