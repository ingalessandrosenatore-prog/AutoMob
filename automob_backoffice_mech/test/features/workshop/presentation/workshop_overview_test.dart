import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview_catalog.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/repositories/workshop_overview_repository.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/get_workshop_overview.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_overview_cubit.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_overview_state.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_gear_period_selector.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_kpi_gauge.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_overview_section.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeWorkshopOverviewRepository repository;

  setUp(() => repository = _FakeWorkshopOverviewRepository());

  WorkshopOverviewCubit createCubit() => WorkshopOverviewCubit(
    GetWorkshopOverview(repository),
    now: () => DateTime(2026, 9, 23),
  );

  test(
    'loads real snapshot once and changes period from the local catalog',
    () async {
      final cubit = createCubit();
      expect(cubit.state, isA<WorkshopOverviewLoading>());
      await cubit.load();
      expect(
        (cubit.state as WorkshopOverviewReady).overview.revenueCents,
        125000,
      );
      cubit.selectPeriod(WorkshopPeriod.month);
      expect(
        (cubit.state as WorkshopOverviewReady).overview.revenueCents,
        2480000,
      );
      expect(
        (cubit.state as WorkshopOverviewReady).overview.completedJobs,
        146,
      );
      cubit.selectPeriod(WorkshopPeriod.year);
      final overview = (cubit.state as WorkshopOverviewReady).overview;
      expect(overview.revenueCents, 26850000);
      expect(overview.availableJobs, 3);
      expect(repository.calls, 1);
      expect(repository.referenceDate, DateTime(2026, 9, 23));
      await cubit.close();
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'tabs update cached KPI on a narrow screen, text scale $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final cubit = createCubit();
        addTearDown(cubit.close);
        await cubit.load();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: const [AmThemeColors.dark]),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: BlocProvider.value(
                  value: cubit,
                  child: const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: WorkshopOverviewSection(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Dati dimostrativi'), findsNothing);
        expect(find.text('€ 1.250'), findsWidgets);
        expect(find.text('€ 895'), findsOneWidget);
        expect(find.byType(WorkshopKpiGauge), findsNWidgets(2));
        expect(find.byType(WorkshopGearPeriodSelector), findsOneWidget);
        final gaugesBottom = tester.getBottomLeft(
          find.byType(WorkshopKpiGauge).last,
        );
        final selectorTop = tester.getTopLeft(
          find.byType(WorkshopGearPeriodSelector),
        );
        expect(selectorTop.dy, greaterThan(gaugesBottom.dy));
        expect(selectorTop.dy - gaugesBottom.dy, closeTo(4, 0.01));
        await tester.tap(find.text('MENSILE'));
        await tester.pumpAndSettle();
        expect(find.text('€ 24.800'), findsWidgets);
        expect(find.text('€ 22.375'), findsOneWidget);
        expect(find.text('149'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _FakeWorkshopOverviewRepository implements WorkshopOverviewRepository {
  int calls = 0;
  DateTime? referenceDate;

  @override
  Future<WorkshopOverviewCatalog> getOverview(DateTime referenceDate) async {
    calls++;
    this.referenceDate = referenceDate;
    return const WorkshopOverviewCatalog(
      day: WorkshopOverview(
        period: WorkshopPeriod.day,
        revenueCents: 125000,
        completedJobs: 8,
        availableJobs: 3,
      ),
      month: WorkshopOverview(
        period: WorkshopPeriod.month,
        revenueCents: 2480000,
        completedJobs: 146,
        availableJobs: 3,
      ),
      year: WorkshopOverview(
        period: WorkshopPeriod.year,
        revenueCents: 26850000,
        completedJobs: 1640,
        availableJobs: 3,
      ),
    );
  }
}
