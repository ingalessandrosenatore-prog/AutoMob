import 'package:auto_mob_v1/core/services/haptic_service.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/widgets/buttons/am_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  setUp(() => AmHaptics.enabled = false);
  tearDown(() => AmHaptics.enabled = true);

  testWidgets('rispetta dimensioni e callback con IconData', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: AmIconButton(
            key: const Key('button'),
            width: 52,
            height: 52,
            radius: 26,
            showShadow: true,
            shadowColor: Colors.black26,
            backgroundColor: Colors.white,
            iconColor: Colors.orange,
            icon: Icons.arrow_forward,
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('button'))), const Size(52, 52));
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    await tester.tap(find.byKey(const Key('button')));
    expect(pressed, isTrue);
  });

  testWidgets('renderizza i dati icona HugeIcons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: AmIconButton(
            width: 48,
            height: 48,
            radius: 24,
            showShadow: false,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.black,
            iconColor: Colors.orange,
            icon: HugeIcons.strokeRoundedArrowRight01,
            iconSize: 28,
            strokeWidth: 2.2,
            onPressed: () {},
          ),
        ),
      ),
    );

    final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
    expect(icon.size, 28);
    expect(icon.strokeWidth, 2.2);
    expect(icon.color, Colors.orange);
  });
}
