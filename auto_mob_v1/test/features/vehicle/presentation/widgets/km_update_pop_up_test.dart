import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_km.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/km_update_cubit.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/km_update_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateVehicleKm extends Mock implements UpdateVehicleKm {}

void main() {
  testWidgets('Aggiungi inserisce i km stimati nel campo', (tester) async {
    final updateVehicleKm = MockUpdateVehicleKm();
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
                createCubit: () => KmUpdateCubit(updateVehicleKm),
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

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, '168243');
  });
}
