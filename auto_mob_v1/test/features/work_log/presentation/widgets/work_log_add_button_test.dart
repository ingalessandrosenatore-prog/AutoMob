import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/work_log/domain/entities/vehicle_option.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/work_log_add_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vehicle = VehicleOption(
    id: 'vehicle-1',
    targa: 'AB123CD',
    nome: 'Giulia',
    brand: 'Alfa Romeo',
    km: 42000,
  );

  testWidgets('il + apre la registrazione e propaga il salvataggio', (
    tester,
  ) async {
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: Center(
            child: WorkLogAddButton(
              vehicle: vehicle,
              onMissingVehicle: () {},
              onSaved: () => saved = true,
              destinationBuilder: (context) => Scaffold(
                key: const Key('registration-page'),
                body: Center(
                  child: TextButton(
                    key: const Key('save-work'),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Salva'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsNothing);
    expect(find.byKey(const Key('registration-page')), findsNothing);

    await tester.tap(find.byKey(WorkLogAddButton.buttonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('registration-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-work')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('registration-page')), findsNothing);
    expect(saved, isTrue);
  });

  testWidgets('senza veicolo esegue il fallback senza aprire il wizard', (
    tester,
  ) async {
    var missingVehicle = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: WorkLogAddButton(
            vehicle: null,
            onMissingVehicle: () => missingVehicle = true,
            onSaved: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(WorkLogAddButton.buttonKey));
    await tester.pump();

    expect(missingVehicle, isTrue);
    expect(find.text('AGGIUNGI LAVORO'), findsNothing);
  });
}
