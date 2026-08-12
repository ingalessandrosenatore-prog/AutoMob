import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_bloc.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_event.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/vehicle_registration_state.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/widgets/registration/work_log_step_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockVehicleRegistrationBloc
    extends MockBloc<VehicleRegistrationEvent, VehicleRegistrationState>
    implements VehicleRegistrationBloc {}

void main() {
  testWidgets('mostra i default quando il draft dei lavori e vuoto', (
    tester,
  ) async {
    final bloc = MockVehicleRegistrationBloc();
    whenListen(
      bloc,
      const Stream<VehicleRegistrationState>.empty(),
      initialState: const VehicleRegistrationState(currentStep: 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Scaffold(
          body: BlocProvider<VehicleRegistrationBloc>.value(
            value: bloc,
            child: const WorkLogStepView(),
          ),
        ),
      ),
    );

    String fieldValue(String label) => tester
        .widget<AmTextField>(
          find.byWidgetPredicate(
            (widget) => widget is AmTextField && widget.label == label,
          ),
        )
        .controller
        .text;

    expect(fieldValue('Chilometri attuali'), '0');
    expect(fieldValue('Km effettuato'), '0');
    expect(fieldValue('Effettuato a km'), '0');
    expect(fieldValue('Ultimo cambio (km)'), '0');
    expect(fieldValue('Ultima inversione (km)'), '0');
    expect(find.text('15.000'), findsNWidgets(2));
    expect(find.text('100.000'), findsOneWidget);
    expect(find.text('40.000'), findsOneWidget);
  });
}
