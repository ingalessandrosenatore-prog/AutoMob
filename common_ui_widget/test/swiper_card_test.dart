import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  testWidgets('accomoda il touch target da 44 px senza overflow verticale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Center(
          child: Swipercard(
            titoloSuperiore: '',
            titolo: 'Aggiungi officina',
            descrizione: 'Collega un officina al tuo veicolo',
            radius: 40,
            borderColor: Colors.orange,
            backGroundColor: Colors.black,
            iconButton: HugeIcons.strokeRoundedAdd01,
            iconColor: Colors.white,
            imageWidth: 150,
            imageHeight: 120,
            radiusButton: 100,
            onTap: () {},
            titoloSuperioreStyle: const TextStyle(fontSize: 11),
            titoloStyle: const TextStyle(fontSize: 14),
            descrizioneStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final decorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration)
        .whereType<ShapeDecoration>()
        .toList();
    expect(decorations.first.gradient, AmThemeColors.light.cardBorderGradient);
    expect(
      decorations.any(
        (decoration) => decoration.gradient == AmThemeColors.light.cardGradient,
      ),
      isTrue,
    );
    expect(
      tester.getSize(find.byType(AmSoftButton)).height,
      greaterThanOrEqualTo(AmControlMetrics.minimumTouchTarget),
    );
  });
}
