import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automob_backoffice_mech/features/notifications/domain/usecases/send_mechanic_notification.dart';
import 'package:automob_backoffice_mech/features/notifications/presentation/bloc/mechanic_notification_cubit.dart';
import 'package:automob_backoffice_mech/features/notifications/presentation/widgets/mechanic_notification_dialog.dart';
import 'mechanic_notification_test.dart' show FakeRepository;

void main() {
  testWidgets(
    'small dark screen keeps close and send reachable with keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = FakeRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [AmThemeColors.dark],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => showMechanicNotificationDialog(
                  context,
                  vehicleName: 'Fiat Panda · AB123CD',
                  createCubit: () => MechanicNotificationCubit(
                    sendNotification: SendMechanicNotification(repository),
                    vehicleId: 'vehicle',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Invia'));
      await tester.pumpAndSettle();
      expect(find.text('Invia').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Chiudi').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Chiudi'));
      await tester.pumpAndSettle();
      expect(repository.requests, isEmpty);
    },
  );
  testWidgets(
    'bell opens modal, chips fill fields, edited text sends and close dismisses',
    (tester) async {
      final repository = FakeRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AmThemeColors.light]),
          home: Scaffold(
            body: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => showMechanicNotificationDialog(
                  context,
                  vehicleName: 'Fiat Panda · AB123CD',
                  createCubit: () => MechanicNotificationCubit(
                    sendNotification: SendMechanicNotification(repository),
                    vehicleId: 'vehicle-123',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();
      expect(find.byType(ChoiceChip), findsNWidgets(4));
      await tester.tap(find.text('Tagliando'));
      await tester.pump();
      expect(find.text('È il momento del tagliando'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('notification-title')),
        'Un promemoria',
      );
      await tester.enterText(
        find.byKey(const Key('notification-body')),
        'Passa in officina per il tagliando.',
      );
      await tester.ensureVisible(find.text('Invia'));
      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();
      expect(repository.requests.single.vehicleId, 'vehicle-123');
      expect(
        repository.requests.single.body,
        'Passa in officina per il tagliando.',
      );
      expect(find.text('Notifica inviata al proprietario.'), findsOneWidget);
      await tester.tap(find.byTooltip('Chiudi'));
      await tester.pumpAndSettle();
      expect(find.byType(MechanicNotificationDialog), findsNothing);
    },
  );
}
