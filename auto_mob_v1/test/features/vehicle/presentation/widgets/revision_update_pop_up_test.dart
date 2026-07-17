import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/core/services/haptic_service.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/widgets/buttons/am_choice_chip.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/revision_interval.dart';
import 'package:auto_mob_v1/features/vehicle/domain/usecases/update_vehicle_revision.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/revision_update_cubit.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/revision_update_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUpdateVehicleRevision extends Mock implements UpdateVehicleRevision {}

void main() {
  late MockUpdateVehicleRevision updateVehicleRevision;

  setUp(() {
    AmHaptics.enabled = false;
    updateVehicleRevision = MockUpdateVehicleRevision();
  });

  tearDown(() {
    AmHaptics.enabled = true;
  });

  Future<void> openPopup(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  RevisionUpdatePopUp<void>(
                    vehicleId: 'v1',
                    currentRevisionDate: null,
                    createCubit: () =>
                        RevisionUpdateCubit(updateVehicleRevision),
                  ).createRoute(context),
                );
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

  DateTime twoYearsFromToday() {
    final now = DateTime.now();
    return RevisionInterval.twoYears.dateFrom(
      DateTime(now.year, now.month, now.day),
    );
  }

  testWidgets('selezionando due anni aggiorna il campo data', (tester) async {
    await openPopup(tester);
    await tester.tap(find.text('2 anni'));
    await tester.pump();

    final expected = twoYearsFromToday();
    final formatted =
        '${expected.day.toString().padLeft(2, '0')}/'
        '${expected.month.toString().padLeft(2, '0')}/${expected.year}';

    expect(find.text(formatted), findsOneWidget);
    final chips = tester.widgetList<AmChoiceChip>(find.byType(AmChoiceChip));
    expect(chips.where((chip) => chip.isSelected), hasLength(1));
    expect(chips.singleWhere((chip) => chip.isSelected).label, '2 anni');
  });

  testWidgets('mostra la conferma dopo il salvataggio', (tester) async {
    final expected = twoYearsFromToday();
    when(
      () => updateVehicleRevision(vehicleId: 'v1', nextRevisionDate: expected),
    ).thenAnswer((_) async => Right(expected));

    await openPopup(tester);
    await tester.tap(find.text('2 anni'));
    await tester.pump();
    await tester.tap(find.text('Salva revisione'));
    await tester.pumpAndSettle();

    expect(find.text('Revisione aggiornata'), findsOneWidget);
    expect(find.textContaining('Nuova scadenza:'), findsOneWidget);

    await tester.tap(find.text('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.text('Aggiorna revisione'), findsNothing);
  });

  testWidgets('mostra messaggio e codice quando il salvataggio fallisce', (
    tester,
  ) async {
    final expected = twoYearsFromToday();
    when(
      () => updateVehicleRevision(vehicleId: 'v1', nextRevisionDate: expected),
    ).thenAnswer(
      (_) async => const Left(
        RemoteFailure(
          'Aggiornamento non consentito dalle policy RLS\n'
          'Codice: 42501',
          code: '42501',
        ),
      ),
    );

    await openPopup(tester);
    await tester.tap(find.text('2 anni'));
    await tester.pump();
    await tester.tap(find.text('Salva revisione'));
    await tester.pumpAndSettle();

    expect(find.text('Aggiornamento non riuscito'), findsOneWidget);
    expect(find.textContaining('42501'), findsOneWidget);
    expect(find.text('Riprova'), findsOneWidget);
  });
}
