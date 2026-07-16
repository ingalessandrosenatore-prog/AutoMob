import 'package:auto_mob_v1/core/widgets/dialog/notification_permission_dialog.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Callback extends Mock {
  void call();
}

void main() {
  testWidgets('mostra spiegazione e attiva il callback', (tester) async {
    final postpone = _Callback();
    final enable = _Callback();
    when(postpone.call).thenReturn(null);
    when(enable.call).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: NotificationPermissionDialog(
            onPostpone: postpone.call,
            onEnable: enable.call,
          ),
        ),
      ),
    );

    expect(find.text('Prenditi cura della tua auto'), findsOneWidget);
    expect(find.textContaining('chilometri'), findsOneWidget);

    await tester.tap(find.text('Attiva'));
    await tester.pump();

    verify(enable.call).called(1);
    verifyNever(postpone.call);
  });

  testWidgets('Non ora richiama il rinvio', (tester) async {
    final postpone = _Callback();
    final enable = _Callback();
    when(postpone.call).thenReturn(null);
    when(enable.call).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.light,
        home: Scaffold(
          body: NotificationPermissionDialog(
            onPostpone: postpone.call,
            onEnable: enable.call,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Non ora'));
    await tester.pump();

    verify(postpone.call).called(1);
    verifyNever(enable.call);
  });
}
