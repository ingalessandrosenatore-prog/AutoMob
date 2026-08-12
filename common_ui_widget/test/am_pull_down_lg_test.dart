import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('apre il menu e inoltra il tap della voce', (tester) async {
    var selections = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AmPullDownLG(
              key: const Key('vehicle-pull-down'),
              brand: '',
              lable: 'Veicolo',
              backgroundColor: Colors.black,
              popupBackgroundColor: Colors.black,
              onTap: () {},
              larghezza: 220,
              buttonIcons: HugeIcons.strokeRoundedCar05,
              buttonIconsSize: 20,
              iconColor: Colors.white,
              textColor: Colors.white,
              buttonLableStyle: const TextStyle(),
              arrow: true,
              liquidGlassEnabled: false,
              children: [
                ItemMorphPopUp(
                  icon: HugeIcons.strokeRoundedCar05,
                  text: 'Alfa Romeo',
                  onTap: () => selections++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('vehicle-pull-down')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Alfa Romeo'), findsOneWidget);

    await tester.tap(find.text('Alfa Romeo'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(selections, 1);
    expect(find.text('Alfa Romeo'), findsNothing);
  });
}
