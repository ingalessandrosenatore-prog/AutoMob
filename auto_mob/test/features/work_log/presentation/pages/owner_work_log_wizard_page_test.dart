import 'package:auto_mob_v1/features/work_log/presentation/pages/owner_work_log_wizard_page.dart';
import 'package:automob_work_log/automob_work_log.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

void main() {
  testWidgets('header centra il titolo e tiene il back compatto a sinistra', (
    tester,
  ) async {
    final repository = _Repository();
    final cubit = WorkLogEditorCubit(createWorkLog: CreateWorkLog(repository));
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: OwnerWorkLogWizardPage(
          workLogContext: const WorkLogLaunchContext(
            vehicleId: 'vehicle-1',
            vehicleName: 'Alfa Romeo Giulia',
            currentKm: 42000,
          ),
          cubit: cubit,
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('owner-work-log-wizard-back-frame'))),
      const Size.square(48),
    );
    final backButton = find.descendant(
      of: find.byKey(const Key('owner-work-log-wizard-back-frame')),
      matching: find.byType(AmSoftButton),
    );
    expect(tester.getSize(backButton), const Size.square(48));
    expect(
      tester.getSize(
        find.descendant(of: backButton, matching: find.byType(OCLiquidGlass)),
      ),
      const Size.square(40),
    );

    final screenCenter = tester.getCenter(find.byType(Scaffold)).dx;
    final titleCenter = tester.getCenter(
      find.byKey(const Key('wizard-app-bar-title')),
    );
    expect(titleCenter.dx, screenCenter);
    expect(tester.getCenter(backButton).dx, lessThan(titleCenter.dx));
  });
}

class _Repository implements WorkLogRepository {
  @override
  Future<Either<String, Unit>> createWorkLog(WorkLogDraft draft) async =>
      right(unit);

  @override
  Future<Either<String, List<WorkLogEntry>>> getVehicleWorks(
    String vehicleId, {
    required int from,
    required int to,
  }) async => right(const []);

  @override
  Future<Either<String, List<WorkLogVehicle>>> getVehicles() async =>
      right(const []);
}
