import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/create_work_log.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/parts_picker_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateWorkLog extends Mock implements CreateWorkLog {}

void main() {
  testWidgets('la selezione visiva resta legata al partId dopo una ricerca', (
    tester,
  ) async {
    final bloc = WorkLogBloc(
      createWorkLog: MockCreateWorkLog(),
      vehicleId: 'vehicle-1',
      initialWorkType: EnumPopUp.altro,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: bloc, child: const PartsPickerBody()),
        ),
      ),
    );

    await tester.tap(find.text('Motore'));
    await tester.pump();
    expect(bloc.state.selectedParts.single.partId, 1);

    await tester.enterText(find.byType(TextField), 'Pistoni');
    await tester.pump();

    final tile = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Pistoni'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = tile.decoration! as BoxDecoration;

    expect(decoration.color, const Color(0xFF151517));
    expect(bloc.state.selectedParts.single.partId, 1);
  });
}
