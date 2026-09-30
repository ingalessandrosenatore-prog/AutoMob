import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, ThemeData theme) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Row(
            children: [
              AmTextField(
                label: 'Nome',
                placeholder: 'Inserisci nome',
                controller: TextEditingController(),
                isRequired: true,
                obscureText: false,
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('AmTextField usa i colori del tema scuro', (tester) async {
    await pumpField(tester, AmTheme.dark);

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.style.color, AmThemeColors.dark.textPrimary);
  });

  testWidgets('AmTextField usa i colori del tema chiaro', (tester) async {
    await pumpField(tester, AmTheme.light);

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.style.color, AmThemeColors.light.textPrimary);
  });
}
