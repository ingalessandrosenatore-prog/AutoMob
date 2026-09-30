import 'package:automob_work_log/src/presentation/work_log_top_app_bar.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 430.0]) {
    testWidgets('controlli ai bordi e titolo centrato a $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: WorkLogTopAppBar(
              leading: AmSoftButton(
                icon: Icons.add,
                width: 40,
                height: 40,
                liquidGlassEnabled: false,
                onPressed: () {},
              ),
              title: const Text(
                'ALFA ROMEO GIULIA',
                textAlign: TextAlign.center,
              ),
              trailing: AmSoftButton(
                icon: Icons.add,
                width: 40,
                height: 40,
                liquidGlassEnabled: false,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      final buttons = find.byType(AmSoftButton);
      expect(tester.getSize(buttons.first), const Size(48, 48));
      expect(tester.getCenter(buttons.first).dx, 32);
      expect(tester.getCenter(buttons.last).dx, width - 32);
      expect(tester.getCenter(find.text('ALFA ROMEO GIULIA')).dx, width / 2);
      expect(
        tester.getSize(find.text('ALFA ROMEO GIULIA')).height,
        greaterThan(20),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
