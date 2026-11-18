import 'package:auto_mob_v1/features/vehicle/presentation/widgets/registration/maintenance_interval_field.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('il campo e lo slider condividono i passi prima e dopo 60000', (
    tester,
  ) async {
    final controller = TextEditingController(text: '60000');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AmThemeColors.dark]),
        home: Scaffold(body: MaintenanceIntervalField(controller: controller)),
      ),
    );

    final slider = find.byType(Slider);
    expect(tester.widget<Slider>(slider).value, 60);
    tester.widget<Slider>(slider).onChanged!(61);
    await tester.pump();
    expect(controller.text, '65000');

    await tester.enterText(find.byType(TextField), '59600');
    expect(MaintenanceIntervalField.read(controller), 60000);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.text, '60000');
  });
}
