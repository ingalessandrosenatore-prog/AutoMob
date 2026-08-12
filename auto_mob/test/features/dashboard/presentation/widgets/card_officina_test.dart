import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/connect_mechanic_cubit.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/disconnect_mechanic_cubit.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/card_officina.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_details_sheet.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/connect_mechanic.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/disconnect_mechanic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectMechanic extends Mock implements ConnectMechanic {}

class MockDisconnectMechanic extends Mock implements DisconnectMechanic {}

void main() {
  const mechanic = MechanicSummary(
    id: 'mechanic-1',
    code: 'OFF-001',
    businessName: 'Officina Giordano',
    address: 'Via Roma 10',
    phone: '+39 081 1234567',
    email: 'info@officinagiordano.it',
  );

  testWidgets('la card aggiungi mostra lo stato esplicito', (tester) async {
    await tester.pumpWidget(const _TestApp(child: AmWorkshopCard.add()));

    expect(find.text('Aggiungi officina'), findsOneWidget);
    expect(find.text('Nuovo collegamento'), findsOneWidget);
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
          builder: (context) => AmWorkshopCard.add(
            onTap: () => Navigator.of(context).push(
              MechanicDetailsPopUp<bool>(
                vehicleId: 'vehicle-1',
                mechanic: null,
                createCubit: () => ConnectMechanicCubit(connectMechanic),
                createDisconnectCubit: () =>
                    DisconnectMechanicCubit(MockDisconnectMechanic()),
              ).createRoute(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aggiungi officina'));
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
                createDisconnectCubit: () =>
                    DisconnectMechanicCubit(MockDisconnectMechanic()),
              ).createRoute(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Officina Giordano'));
    await tester.pumpAndSettle();

    expect(find.text('La tua officina'), findsOneWidget);
    expect(find.text('Via Roma 10'), findsOneWidget);
    expect(find.text('info@officinagiordano.it'), findsOneWidget);
    expect(find.text('+39 081 1234567'), findsOneWidget);
  });

  testWidgets('lo swiper parte da Aggiungi e apre la card selezionata', (
    tester,
  ) async {
    var addTaps = 0;
    MechanicSummary? selected;

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 360,
          child: AmWorkshopSwiper(
            mechanics: const [mechanic],
            onAdd: () => addTaps++,
            onMechanicTap: (value) => selected = value,
          ),
        ),
      ),
    );

    final visibleAdd = find.text('Aggiungi officina').hitTestable();
    expect(visibleAdd, findsOneWidget);
    await tester.tap(visibleAdd);
    expect(addTaps, 1);

    await tester.drag(visibleAdd, const Offset(-320, 0));
    await tester.pumpAndSettle();
    final visibleMechanic = find.text('Officina Giordano').hitTestable();
    expect(visibleMechanic, findsOneWidget);

    await tester.tap(visibleMechanic);
    expect(selected, mechanic);
  });

  testWidgets('con zero officine mostra solo Add e disabilita lo swipe', (
    tester,
  ) async {
    var addTaps = 0;

    await tester.pumpWidget(
      _TestApp(
        child: SizedBox(
          width: 360,
          child: AmWorkshopSwiper(
            mechanics: const [],
            onAdd: () => addTaps++,
            onMechanicTap: (_) {},
          ),
        ),
      ),
    );

    final addCard = find.text('Aggiungi officina').hitTestable();
    expect(addCard, findsOneWidget);
    await tester.drag(addCard, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi officina').hitTestable(), findsOneWidget);

    await tester.tap(addCard);
    expect(addTaps, 1);
  });

  testWidgets('dal dettaglio scollega dopo la conferma', (tester) async {
    final disconnectMechanic = MockDisconnectMechanic();
    when(
      () =>
          disconnectMechanic(vehicleId: 'vehicle-1', mechanicId: 'mechanic-1'),
    ).thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) => AmWorkshopCard(
            mechanic: mechanic,
            onTap: () => Navigator.of(context).push(
              MechanicDetailsPopUp<bool>(
                vehicleId: 'vehicle-1',
                mechanic: mechanic,
                createCubit: () => ConnectMechanicCubit(MockConnectMechanic()),
                createDisconnectCubit: () =>
                    DisconnectMechanicCubit(disconnectMechanic),
              ).createRoute(context),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Officina Giordano'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('disconnect_mechanic_button')));
    await tester.pumpAndSettle();
    expect(find.text('Scollega officina'), findsOneWidget);

    await tester.tap(find.text('Scollega'));
    await tester.pumpAndSettle();
    expect(find.text('Officina scollegata'), findsOneWidget);
    verify(
      () =>
          disconnectMechanic(vehicleId: 'vehicle-1', mechanicId: 'mechanic-1'),
    ).called(1);
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
