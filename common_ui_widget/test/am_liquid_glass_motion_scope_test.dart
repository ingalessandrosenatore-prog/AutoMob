import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  testWidgets(
    'disabilita tutti i controlli glass mentre il PageView si muove',
    (tester) async {
      final isMoving = ValueNotifier(false);
      addTearDown(isMoving.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AmLiquidGlassMotionScope(
            isMoving: isMoving,
            child: Column(
              children: [
                AmSoftButton(
                  width: 44,
                  height: 44,
                  icon: Icons.add,
                  onPressed: () {},
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
                  arrow: false,
                  children: const [],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(OCLiquidGlass), findsNWidgets(2));
      expect(find.byType(AmFlatGlass), findsNothing);

      isMoving.value = true;
      await tester.pump();

      expect(find.byType(OCLiquidGlass), findsNothing);
      expect(find.byType(AmFlatGlass), findsNWidgets(2));

      isMoving.value = false;
      await tester.pump();

      expect(find.byType(OCLiquidGlass), findsNWidgets(2));
      expect(find.byType(AmFlatGlass), findsNothing);
    },
  );
}
