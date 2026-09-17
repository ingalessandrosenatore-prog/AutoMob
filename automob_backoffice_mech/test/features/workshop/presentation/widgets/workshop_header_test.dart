import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_header.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('il pulsante settings inoltra la navigazione', (tester) async {
    var settingsPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkshopAppBar(
            mechanicName: 'Mario',
            onSettingsPressed: () => settingsPressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AmSoftButton));
    await tester.pump();

    expect(settingsPressed, isTrue);
  });
}
