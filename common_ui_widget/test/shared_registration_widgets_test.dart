import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
