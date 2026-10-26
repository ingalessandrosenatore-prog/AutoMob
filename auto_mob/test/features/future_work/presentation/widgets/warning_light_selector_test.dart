import 'package:auto_mob_v1/features/future_work/domain/usecases/create_future_work_report.dart';
import 'package:auto_mob_v1/features/future_work/presentation/bloc/future_work_report_cubit.dart';
import 'package:auto_mob_v1/features/future_work/presentation/widgets/warning_light_selector.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CreateReport extends Mock implements CreateFutureWorkReport {}

void main() {
  testWidgets(
    'two square rows scroll horizontally and expose distinct engine modes',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = FutureWorkReportCubit(_CreateReport());
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const WarningLightSelector(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ExpansionTile), findsNothing);
      final first = tester.getRect(
        find.byKey(const ValueKey('warning-choice-S01-red-false')),
      );
      final second = tester.getRect(
        find.byKey(const ValueKey('warning-choice-S02-amber-false')),
      );
      final third = tester.getRect(
        find.byKey(const ValueKey('warning-choice-S03-amber-false')),
      );
      expect(first.width, closeTo(first.height, 0.1));
      expect(second.left, first.left);
      expect(second.top, greaterThan(first.bottom));
      expect(third.top, first.top);
      expect(third.left, greaterThan(first.right));
      final grid = find.byKey(const ValueKey('warning-light-grid'));
      await tester.drag(grid, const Offset(-800, 0));
      await tester.pump(const Duration(seconds: 1));
      final steady = find.byKey(
        const ValueKey('warning-choice-S10-amber-false'),
      );
      final flashing = find.byKey(
        const ValueKey('warning-choice-S10-amber-true'),
      );
      await tester.ensureVisible(steady);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(steady);
      await tester.pump();
      await tester.ensureVisible(flashing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(flashing);
      await tester.pump();
      expect(cubit.state.warningLights.length, 2);
      expect(cubit.state.warningLights.map((light) => light.flashing), [
        false,
        true,
      ]);
      await tester.tap(steady);
      await tester.pump();
      expect(cubit.state.warningLights.single.flashing, isTrue);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
