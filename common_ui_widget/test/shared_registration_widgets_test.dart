import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('il soft edge usa fasce da 20 px e punti 0.5 e 1', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: const Scaffold(
          body: SizedBox.expand(child: AmEdgeBlur(child: Placeholder())),
        ),
      ),
    );

    final edgeFinder = find.descendant(
      of: find.byType(AmEdgeBlur),
      matching: find.byType(Positioned),
    );
    final edges = tester.widgetList<Positioned>(edgeFinder).toList();
    expect(edges, hasLength(2));
    expect(edges.map((edge) => edge.height), everyElement(20));

    final decoratedBoxes = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(AmEdgeBlur),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where((box) => box.decoration is BoxDecoration)
        .toList();
    final gradients = decoratedBoxes
        .map((box) => box.decoration as BoxDecoration)
        .map((decoration) => decoration.gradient)
        .whereType<LinearGradient>()
        .toList();
    expect(gradients, hasLength(2));
    expect(gradients, everyElement(hasStops(const [0, 0.5, 1])));
  });

  testWidgets('la progress bar espone i tre passaggi del wizard', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: const Scaffold(
          body: AmWizardProgress(
            steps: ['Anagrafica', 'Officina', 'Conferma'],
            currentStep: 1,
          ),
        ),
      ),
    );

    expect(find.text('Anagrafica'), findsOneWidget);
    expect(find.text('Officina'), findsOneWidget);
    expect(find.text('Conferma'), findsOneWidget);
    expect(find.bySemanticsLabel('Passaggio 2 di 3: Officina'), findsOneWidget);
  });

  testWidgets('il campo password cambia visibilita senza stato della pagina', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Password1!');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              AmTextField(
                label: 'Password',
                placeholder: 'Password',
                controller: controller,
                isRequired: true,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
  });

  testWidgets('il bottone in caricamento blocca invii duplicati', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AmMainFab(
            label: 'Continua',
            color: Colors.orange,
            onPressed: () => presses++,
            isLoading: true,
            width: 220,
            height: 54,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AmMainFab));
    expect(presses, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

Matcher hasStops(List<double> stops) => predicate<LinearGradient>(
  (gradient) => gradient.stops.toString() == stops.toString(),
  'ha gli stop $stops',
);
