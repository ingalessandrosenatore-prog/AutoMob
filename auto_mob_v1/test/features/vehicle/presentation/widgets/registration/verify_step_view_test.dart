import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/widgets/input/textfield.dart';
import 'package:auto_mob_v1/core/widgets/dialog/am_status_dialog.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_draft.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_event.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_state.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/registration/verify_step_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleRegistrationBloc
    extends MockBloc<VehicleRegistrationEvent, VehicleRegistrationState>
    implements VehicleRegistrationBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(VerifyStepSubmitted());
  });

  testWidgets('inizializza il controller targa dalla bozza gia valorizzata', (
    tester,
  ) async {
    final bloc = MockVehicleRegistrationBloc();
    const state = VehicleRegistrationState(
      currentStep: 2,
      draft: VehicleDraft(
        targa: 'AB123CD',
        marca: 'Fiat',
        modello: 'Panda',
        anno: 2020,
        carburante: 'Benzina',
        cilindrata: 1200,
        potenzaCv: 69,
        datiInModifica: true,
      ),
    );
    whenListen(
      bloc,
      const Stream<VehicleRegistrationState>.empty(),
      initialState: state,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: BlocProvider<VehicleRegistrationBloc>.value(
            value: bloc,
            child: const VerifyStepView(),
          ),
        ),
      ),
    );

    final targa = tester.widget<AmTextField>(
      find.byWidgetPredicate(
        (widget) => widget is AmTextField && widget.label == 'Targa',
      ),
    );
    expect(targa.controller.text, 'AB123CD');
  });

  testWidgets('mostra il popup quando mancano campi obbligatori', (
    tester,
  ) async {
    final bloc = MockVehicleRegistrationBloc();
    const state = VehicleRegistrationState(
      currentStep: 2,
      draft: VehicleDraft(targa: 'AB123CD', datiInModifica: true),
    );
    whenListen(
      bloc,
      const Stream<VehicleRegistrationState>.empty(),
      initialState: state,
    );
    final key = GlobalKey<VerifyStepViewState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: BlocProvider<VehicleRegistrationBloc>.value(
            value: bloc,
            child: VerifyStepView(key: key),
          ),
        ),
      ),
    );

    key.currentState!.submit();
    await tester.pumpAndSettle();

    expect(find.byType(AmStatusDialog), findsOneWidget);
    expect(find.text('Campi obbligatori mancanti'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });
}
