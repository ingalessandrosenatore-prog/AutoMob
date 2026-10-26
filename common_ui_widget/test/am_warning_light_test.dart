import 'package:flutter_svg/flutter_svg.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generic appearances are unique and include both engine modes', () {
    final codes = amSelectableWarningLights
        .map((option) => option.code)
        .toList();
    final identities = amSelectableWarningLights
        .map((option) => (option.code, option.color, option.flashing))
        .toList();
    expect(identities.toSet().length, identities.length);
    expect(
      identities,
      containsAll([('S10', 'amber', false), ('S10', 'amber', true)]),
    );
    expect(
      amSelectableWarningLights.every(
        (option) => AmWarningLightData(
          code: option.code,
          color: option.color,
          flashing: option.flashing,
        ).assetPath.endsWith('.svg'),
      ),
      isTrue,
    );
    expect(codes, containsAll(['S12', 'S14', 'S03', 'STOP']));
    expect(
      codes.toSet().intersection({'S19', 'S21', 'S29', 'S30', 'S37'}),
      isEmpty,
    );
    expect(
      amSelectableWarningLights
          .where((option) => option.code == 'S35')
          .every((option) => !option.flashing),
      isTrue,
    );
    expect(codes, isNot(contains('S11'))); // EPC
    expect(codes, isNot(contains('S13'))); // Oil uses one generic symbol.
    expect(codes, isNot(contains('S22'))); // Manufacturer-specific powertrain.
    expect(
      codes,
      isNot(contains('S24')),
    ); // Fuel-selector-specific indications.
    expect(codes.every(amWarningLightCatalog.containsKey), isTrue);
    expect(
      amWarningLightCatalog.containsKey('S11'),
      isTrue,
    ); // Historical reports.
  });

  testWidgets('tap shows the board message and hides the user fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmWarningLights(
            lights: [
              AmWarningLightData(
                code: 'S10',
                color: 'amber',
                description: 'Rumore percepito',
              ),
              AmWarningLightData(
                code: 'S10',
                color: 'amber',
                onboardMessage: '  Controllare motore  ',
                description: 'Vibrazione',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AmWarningLight), findsOneWidget);
    expect(find.textContaining('Controllare motore'), findsNothing);
    await tester.tap(find.byType(AmWarningLight));
    await tester.pumpAndSettle();
    expect(find.textContaining('Avaria motore'), findsOneWidget);
    expect(find.textContaining('Controllare motore'), findsOneWidget);
    expect(find.textContaining('Rumore percepito'), findsNothing);
    expect(find.textContaining('Vibrazione'), findsNothing);
  });

  testWidgets('tap uses the user description when there is no board message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmWarningLight(
            light: AmWarningLightData(
              code: 'S10',
              color: 'amber',
              onboardMessage: '  ',
              description: 'Rumore percepito',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AmWarningLight));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rumore percepito'), findsOneWidget);
  });

  testWidgets('every selectable symbol loads its packaged SVG', (tester) async {
    final codes = amSelectableWarningLights
        .map((option) => option.code)
        .toSet();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final code in codes)
                AmWarningLight(
                  light: AmWarningLightData(code: code, color: 'amber'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SvgPicture), findsNWidgets(codes.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows color and only animates flashing observations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmWarningLight(
            light: AmWarningLightData(
              code: 'S03',
              color: 'red',
              flashing: true,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter,
      const ColorFilter.mode(Color(0xFFFF4D57), BlendMode.srcIn),
    );
    final before = tester
        .widget<FadeTransition>(find.byType(FadeTransition).last)
        .opacity
        .value;
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value,
      isNot(before),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmWarningLight(
            light: AmWarningLightData(code: 'S03', color: 'amber'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value,
      1,
    );
  });
  testWidgets(
    'deduplicates observations and scrolls many icons in narrow cards',
    (tester) async {
      const light = AmWarningLightData(code: 'S03', color: 'amber');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: AmWarningLights(
                compact: true,
                lights: [
                  light,
                  light,
                  for (final code in amWarningLightCatalog.keys.where(
                    (key) => key != 'S03',
                  ))
                    AmWarningLightData(code: code, color: 'red'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        find.byType(AmWarningLight),
        findsNWidgets(amWarningLightCatalog.length),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AmWarningLight(
            light: AmWarningLightData(
              code: 'S03',
              color: 'red',
              flashing: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FadeTransition>(find.byType(FadeTransition).last)
          .opacity
          .value,
      1,
    );
  });
}
