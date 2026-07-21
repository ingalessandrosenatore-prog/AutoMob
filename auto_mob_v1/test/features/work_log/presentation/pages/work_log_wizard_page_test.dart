import 'package:auto_mob_v1/core/di/injection_container.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/work_log/domain/usecases/create_work_log.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/pages/work_log_wizard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateWorkLog extends Mock implements CreateWorkLog {}

void main() {
  tearDown(() async => sl.reset());

  testWidgets('mostra subito il tipo lavoro ricevuto in ingresso', (
    tester,
  ) async {
    late WorkLogBloc createdBloc;
    sl.registerFactoryParam<WorkLogBloc, String, EnumPopUp>((
      vehicleId,
      initialWorkType,
    ) {
      createdBloc = WorkLogBloc(
        createWorkLog: MockCreateWorkLog(),
        vehicleId: vehicleId,
        initialWorkType: initialWorkType,
      );
      return createdBloc;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: const WorkLogWizardPage(
          vehicleId: 'vehicle-1',
          currentKm: 42000,
          initialWorkType: EnumPopUp.revisione,
        ),
      ),
    );
    await tester.pump();

    expect(createdBloc.state.type, EnumPopUp.revisione);
    final dropdown = tester.widget<DropdownButtonFormField<EnumPopUp>>(
      find.byType(DropdownButtonFormField<EnumPopUp>),
    );
    expect(dropdown.initialValue, EnumPopUp.revisione);
  });

  testWidgets(
    'la tastiera restringe il PageView senza spostare la bottom bar',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 700);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetViewInsets);

      sl.registerFactoryParam<WorkLogBloc, String, EnumPopUp>((
        vehicleId,
        initialWorkType,
      ) {
        return WorkLogBloc(
          createWorkLog: MockCreateWorkLog(),
          vehicleId: vehicleId,
          initialWorkType: initialWorkType,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: const WorkLogWizardPage(
            vehicleId: 'vehicle-1',
            currentKm: 42000,
            initialWorkType: EnumPopUp.revisione,
          ),
        ),
      );
      await tester.pump();

      final pageViewFinder = find.byType(PageView);
      final continueFinder = find.text('CONTINUA');
      final pageHeightWithoutKeyboard = tester.getSize(pageViewFinder).height;
      final buttonCenterWithoutKeyboard = tester.getCenter(continueFinder);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();

      final pageHeightWithKeyboard = tester.getSize(pageViewFinder).height;
      final buttonCenterWithKeyboard = tester.getCenter(continueFinder);

      expect(buttonCenterWithKeyboard, buttonCenterWithoutKeyboard);
      // Bottom bar: 20 px sopra + pulsante da 52 px + safe area (34 + 8).
      expect(pageHeightWithKeyboard, pageHeightWithoutKeyboard - 186);
    },
  );
}
