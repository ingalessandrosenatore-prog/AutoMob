import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/registration/vehicle_registration_close_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    ValueChanged<VehicleRegistrationCloseAction?> onResult,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                onResult(await showVehicleRegistrationCloseDialog(context));
              },
              child: const Text('Apri'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra il popup di chiusura uniforme con le due azioni', (
    tester,
  ) async {
    VehicleRegistrationCloseAction? result;
    await openDialog(tester, (value) => result = value);

    expect(find.byType(AmStatusDialog), findsOneWidget);
    expect(find.text('Uscire dalla registrazione?'), findsOneWidget);
    expect(
      find.text(
        'Puoi salvare la bozza e riprendere in seguito senza perdere i dati inseriti.',
      ),
      findsOneWidget,
    );
    expect(find.text('Scarta e chiudi'), findsOneWidget);
    expect(find.text('Salva draft e chiudi'), findsOneWidget);

    await tester.tap(find.text('Salva draft e chiudi'));
    await tester.pumpAndSettle();
    expect(result, VehicleRegistrationCloseAction.saveDraft);
  });

  testWidgets('restituisce la scelta di scartare il draft', (tester) async {
    VehicleRegistrationCloseAction? result;
    await openDialog(tester, (value) => result = value);

    await tester.tap(find.text('Scarta e chiudi'));
    await tester.pumpAndSettle();

    expect(result, VehicleRegistrationCloseAction.discardDraft);
    expect(find.byType(AmStatusDialog), findsNothing);
  });
}
