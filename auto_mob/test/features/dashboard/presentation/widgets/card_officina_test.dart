import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/connect_mechanic_cubit.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/card_officina.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_details_sheet.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/connect_mechanic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectMechanic extends Mock implements ConnectMechanic {}

void main() {
  const mechanic = MechanicSummary(
    id: 'mechanic-1',
    code: 'OFF-001',
    businessName: 'Officina Giordano',
    address: 'Via Roma 10',
    phone: '+39 081 1234567',
    email: 'info@officinagiordano.it',
  );

  testWidgets('senza meccanico mostra lo stato vuoto', (tester) async {
    await tester.pumpWidget(
      const _TestApp(child: AmWorkshopCard(mechanic: null)),
    );

    expect(find.text('Nessun meccanico collegato'), findsOneWidget);
    expect(find.text('Il tuo meccanico'), findsOneWidget);
  });

  testWidgets('senza meccanico apre il popup e consente il collegamento', (
    tester,
  ) async {
    final connectMechanic = MockConnectMechanic();
    when(
      () => connectMechanic(vehicleId: 'vehicle-1', mechanicCode: 'OFF-001'),
    ).thenAnswer((_) async => const Right(mechanic));

    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) => AmWorkshopCard(
            mechanic: null,
            onTap: () => Navigator.of(context).push(
              MechanicDetailsPopUp<bool>(
                vehicleId: 'vehicle-1',
                mechanic: null,
                createCubit: () => ConnectMechanicCubit(connectMechanic),
              ).createRoute(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Nessun meccanico collegato'));
    await tester.pumpAndSettle();

    expect(find.text('Aggiungi il tuo meccanico di fiducia'), findsOneWidget);
    expect(find.text('COLLEGA'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'OFF-001');
    await tester.pump();
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text('COLLEGA'));
    await tester.tap(find.byKey(const Key('connect_mechanic_button')));
    await tester.pumpAndSettle();

    expect(find.text('Meccanico collegato'), findsOneWidget);
    expect(find.text('Fatto'), findsOneWidget);
  });

  testWidgets('il tap apre il popup con tutti i contatti', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) => AmWorkshopCard(
            mechanic: mechanic,
            onTap: () => Navigator.of(context).push(
              MechanicDetailsPopUp(
                vehicleId: 'vehicle-1',
                mechanic: mechanic,
                createCubit: () => ConnectMechanicCubit(MockConnectMechanic()),
              ).createRoute(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Officina Giordano'));
    await tester.pumpAndSettle();

    expect(find.text('Il tuo meccanico'), findsNWidgets(2));
    expect(find.text('Via Roma 10'), findsOneWidget);
    expect(find.text('info@officinagiordano.it'), findsOneWidget);
    expect(find.text('+39 081 1234567'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  final Widget child;

  const _TestApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AmThemeColors.light]),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
