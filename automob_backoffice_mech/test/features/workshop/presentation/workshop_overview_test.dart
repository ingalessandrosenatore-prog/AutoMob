import 'package:automob_backoffice_mech/features/workshop/data/datasources/workshop_overview_demo_data_source.dart';
import 'package:automob_backoffice_mech/features/workshop/data/repositories/workshop_overview_repository_impl.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/usecases/get_workshop_overview.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_overview_cubit.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_overview_section.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkshopOverviewCubit createCubit() => WorkshopOverviewCubit(
    GetWorkshopOverview(
      WorkshopOverviewRepositoryImpl(const WorkshopOverviewDemoDataSource()),
    ),
  );

  test(
    'demo period updates totals while pending work remains current',
    () async {
      final cubit = createCubit();
      expect(cubit.state.revenue, 1250);
      cubit.selectPeriod(WorkshopPeriod.month);
      expect(cubit.state.revenue, 24800);
      expect(cubit.state.completedJobs, 146);
      cubit.selectPeriod(WorkshopPeriod.year);
      expect(cubit.state.revenue, 268500);
      expect(cubit.state.availableJobs, 3);
      expect(cubit.state.potentialRevenue, 2800);
      await cubit.close();
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'tabs update demo cards on a narrow screen, text scale $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final cubit = createCubit();
        addTearDown(cubit.close);
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
        expect(find.text('Dati dimostrativi'), findsNothing);
        expect(find.text('€ 1.250'), findsOneWidget);
        await tester.tap(find.text('Mensile'));
        await tester.pumpAndSettle();
        expect(find.text('€ 24.800'), findsOneWidget);
        expect(
          find.textContaining('rispetto', findRichText: true),
          findsNothing,
        );
        expect(
          find.textContaining('18 % in più', findRichText: true),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.north_east_rounded), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
