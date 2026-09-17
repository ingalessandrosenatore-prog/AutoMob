import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa la superficie statica light con misure e colori richiesti', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: const Scaffold(
          body: AmStatusDialog(title: 'Caricamento', showSpinner: true),
        ),
      ),
    );

    final staticSurface = find.byKey(
      const Key('am-status-dialog-static-surface'),
    );
    expect(tester.getSize(staticSurface).width, 248);
    expect(find.byKey(const Key('am-status-dialog-backdrop-blur')), findsOne);

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('am-status-dialog-gradient-surface')),
    );
    final decoration = surface.decoration as ShapeDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.begin, Alignment.topLeft);
    expect(gradient.end, Alignment.bottomRight);
    expect(gradient.colors, const [
      Color.fromRGBO(255, 255, 255, 0.782),
      Color.fromRGBO(250, 250, 252, 0.748),
      Color.fromRGBO(241, 241, 242, 0.714),
    ]);
    final shape = decoration.shape as SmoothRectangleBorder;
    expect(shape.borderRadius.toString(), contains('30.0'));
    expect(shape.side.width, 0.75);
    expect(shape.side.color, const Color.fromRGBO(255, 255, 255, 0.72));

    final outer = tester.widget<DecoratedBox>(staticSurface);
    final outerDecoration = outer.decoration as ShapeDecoration;
    expect(outerDecoration.shadows, const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.12),
        offset: Offset(0, 10),
        blurRadius: 24,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.08),
        offset: Offset(0, 3),
        blurRadius: 8,
      ),
    ]);
  });

  testWidgets('usa i colori statici dark e mantiene i bottoni esterni', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: AmStatusDialog(
            title: 'Errore',
            actions: [
              AmDialogAction(
                label: 'Riprova',
                color: Colors.red,
                onPressed: () => pressed = true,
              ),
            ],
          ),
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const Key('am-status-dialog-gradient-surface')),
    );
    final decoration = surface.decoration as ShapeDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, const [
      Color.fromRGBO(44, 44, 46, 0.714),
      Color.fromRGBO(28, 28, 30, 0.680),
      Color.fromRGBO(18, 18, 20, 0.646),
    ]);
    final shape = decoration.shape as SmoothRectangleBorder;
    expect(shape.side.color, const Color.fromRGBO(255, 255, 255, 0.14));

    await tester.tap(find.text('Riprova'));
    expect(pressed, isTrue);
  });

  testWidgets('sfoca e scurisce lievemente la pagina dietro al dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAmStatusDialog<void>(
              context,
              title: 'Errore',
              message: 'Riprova',
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    final barriers = tester.widgetList<ModalBarrier>(find.byType(ModalBarrier));
    expect(barriers, isNotEmpty);
    expect(
      barriers.any(
        (barrier) => barrier.color == Colors.black.withValues(alpha: 0.07),
      ),
      isTrue,
    );
    expect(find.byKey(const Key('am-status-dialog-page-blur')), findsOneWidget);
  });
}
