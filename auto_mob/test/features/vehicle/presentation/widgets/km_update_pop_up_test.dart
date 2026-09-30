import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_km.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/add_fuel_expense.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/km_update_cubit.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/km_update_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateVehicleKm extends Mock implements UpdateVehicleKm {}

class MockAddFuelExpense extends Mock implements AddFuelExpense {}

void main() {
  testWidgets('Aggiungi inserisce i km stimati nel campo', (tester) async {
    final updateVehicleKm = MockUpdateVehicleKm();
    final addFuelExpense = MockAddFuelExpense();
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              KmUpdatePopUp<void>(
                vehicleId: 'vehicle-1',
                currentKm: '166600',
                estimatedKm: 168243,
                createCubit: () =>
                    KmUpdateCubit(updateVehicleKm, addFuelExpense),
              ).createRoute(context),
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();

    expect(find.text('KM stimati: 168.243'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('apply-estimated-km-button')),
    );
    await tester.tap(find.byKey(const Key('apply-estimated-km-button')));
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.descendant(
        of: find.byKey(const Key('new-km-field')),
        matching: find.byType(TextFormField),
      ),
    );
    expect(field.controller?.text, '168243');
  });

  testWidgets('mostra costo e litri carburante come campi opzionali', (
    tester,
  ) async {
    final updateVehicleKm = MockUpdateVehicleKm();
    final addFuelExpense = MockAddFuelExpense();
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              KmUpdatePopUp<void>(
                vehicleId: 'vehicle-1',
                currentKm: '166600',
                estimatedKm: 168243,
                createCubit: () =>
                    KmUpdateCubit(updateVehicleKm, addFuelExpense),
              ).createRoute(context),
            ),
            child: const Text('Apri'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('fuel-cost-field')),
      250,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.byKey(const Key('fuel-cost-field')), findsOneWidget);
    expect(find.byKey(const Key('fuel-liters-field')), findsOneWidget);
    expect(find.text('EURO CARBURANTE', findRichText: true), findsOneWidget);
    expect(find.text('NUMERO LITRI', findRichText: true), findsOneWidget);
  });
}
