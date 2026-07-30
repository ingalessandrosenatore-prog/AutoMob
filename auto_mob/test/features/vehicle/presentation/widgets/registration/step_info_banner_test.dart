import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/registration/step_info_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('mostra il warning di recupero parziale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: const Scaffold(
          body: StepInfoBanner(
            color: Colors.amber,
            icon: HugeIcons.strokeRoundedAlert01,
            text: 'Dati recuperati parzialmente',
          ),
        ),
      ),
    );

    expect(find.text('Dati recuperati parzialmente'), findsOneWidget);
    expect(find.byType(HugeIcon), findsOneWidget);
  });
}
