import 'dart:async';

import 'package:auto_mob_v1/core/error/exceptions/exception.dart';
import 'package:auto_mob_v1/features/future_work/domain/entities/future_work_report.dart';
import 'package:auto_mob_v1/features/future_work/domain/usecases/create_future_work_report.dart';
import 'package:auto_mob_v1/features/future_work/presentation/bloc/future_work_report_cubit.dart';
import 'package:auto_mob_v1/features/future_work/presentation/pages/future_work_report_page.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _CreateReport extends Mock implements CreateFutureWorkReport {}

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'header e azione restano flottanti durante lo scroll a $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = FutureWorkReportCubit(_CreateReport());
        addTearDown(cubit.close);
        await tester.pumpWidget(_app(cubit));
        expect(find.byType(AmSoftButton), findsOneWidget);
        expect(find.byType(SmartEdge), findsOneWidget);
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).extendBodyBehindAppBar,
          isTrue,
        );
        final title = find.byKey(const Key('wizard-app-bar-title'));
        final submit = find.byKey(const ValueKey('future-work-submit'));
        final titlePosition = tester.getCenter(title);
        final buttonPosition = tester.getCenter(submit);
        final scroll = find.byKey(const Key('future-work-form-scroll'));
        await tester.drag(scroll, const Offset(0, -650));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.getCenter(title), titlePosition);
        expect(tester.getCenter(submit), buttonPosition);
        expect(tester.widget<SmallPrincipal>(submit).onPressed, isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getBottomLeft(submit).dy, lessThanOrEqualTo(844 - 280));
        expect(tester.getCenter(title), titlePosition);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'campi comuni conservano i testi e si disabilitano durante il salvataggio',
    (tester) async {
      final createReport = _CreateReport();
      final cubit = FutureWorkReportCubit(createReport);
      addTearDown(cubit.close);
      final pending = Completer<Either<Failure, FutureWorkReport>>();
      final date = DateTime.now().add(const Duration(days: 1));
      when(
        () => createReport(
          vehicleId: 'v1',
          description: 'Rumore',
          onboardMessage: 'Controllare motore',
          warningLights: const [],
          reminderDate: DateTime(date.year, date.month, date.day),
        ),
      ).thenAnswer((_) => pending.future);
      await tester.pumpWidget(_app(cubit));
      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(field('future-work-onboard-message'));
      await tester.enterText(
        field('future-work-onboard-message'),
        'Controllare motore',
      );
      await tester.ensureVisible(field('future-work-description'));
      await tester.enterText(field('future-work-description'), 'Rumore');
      cubit.reminderDateChanged(date);
      await tester.pump();
      final submit = find.byKey(const ValueKey('future-work-submit'));
      await tester.tap(submit);
      await tester.pump();
      expect(tester.widget<SmallPrincipal>(submit).isLoading, isTrue);
      final board = tester.widget<TextFormField>(
        field('future-work-onboard-message'),
      );
      expect(board.enabled, isFalse);
      expect(
        tester
            .widget<AmTextField>(
              find.byKey(const ValueKey('future-work-description')),
            )
            .maxLength,
        1000,
      );
      expect(cubit.state.description, 'Rumore');
      expect(cubit.state.onboardMessage, 'Controllare motore');
      pending.complete(const Left(NetworkFailure()));
      await tester.pump();
      expect(tester.widget<SmallPrincipal>(submit).isLoading, isFalse);
      expect(cubit.state.description, 'Rumore');
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app(FutureWorkReportCubit cubit) => MaterialApp(
  theme: AmTheme.dark,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: const EdgeInsets.only(top: 30)),
      child: FutureWorkReportPage(
        vehicleId: 'v1',
        vehicleName: 'Alfa Romeo Stelvio',
        cubit: cubit,
      ),
    ),
  ),
);
