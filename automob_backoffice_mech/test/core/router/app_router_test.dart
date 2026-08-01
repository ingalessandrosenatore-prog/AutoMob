import 'package:automob_backoffice_mech/core/router/app_route_names.dart';
import 'package:automob_backoffice_mech/core/router/app_router.dart';
import 'package:automob_backoffice_mech/core/router/app_router_dependencies.dart';
import 'package:automob_backoffice_mech/core/router/auth_navigation_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('auth guard moves unauthenticated users to login', (
    tester,
  ) async {
    final authStatus = ValueNotifier(AuthNavigationStatus.unauthenticated);
    final router = _createRouter(authStatus);
    addTearDown(() {
      router.dispose();
      authStatus.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);

    authStatus.value = AuthNavigationStatus.authenticated;
    await tester.pumpAndSettle();

    expect(find.text('workshop'), findsOneWidget);
    expect(find.text('Officina'), findsOneWidget);
    expect(find.text('Abbonamento'), findsOneWidget);
  });

  testWidgets('switching tabs preserves the workshop state', (tester) async {
    final authStatus = ValueNotifier(AuthNavigationStatus.authenticated);
    final router = _createRouter(authStatus);
    addTearDown(() {
      router.dispose();
      authStatus.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('workshop-draft')),
      'bozza mantenuta',
    );

    await tester.tap(find.text('Abbonamento'));
    await tester.pumpAndSettle();
    expect(find.text('subscription'), findsOneWidget);

    await tester.tap(find.text('Officina'));
    await tester.pumpAndSettle();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, 'bozza mantenuta');
  });

  testWidgets(
    'la conferma pendente resta sulla route email fino alla sessione',
    (tester) async {
      final authStatus = ValueNotifier(
        AuthNavigationStatus.emailVerificationRequired,
      );
      final router = _createRouter(authStatus);
      addTearDown(() {
        router.dispose();
        authStatus.dispose();
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('verify-email'), findsOneWidget);

      authStatus.value = AuthNavigationStatus.authenticated;
      await tester.pumpAndSettle();
      expect(find.text('workshop'), findsOneWidget);
    },
  );

  testWidgets('vehicle routes support nested pushes for mechanic work', (
    tester,
  ) async {
    final authStatus = ValueNotifier(AuthNavigationStatus.authenticated);
    final router = _createRouter(authStatus);
    addTearDown(() {
      router.dispose();
      authStatus.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.pushNamed(
      AppRouteNames.vehicleConfiguration,
      pathParameters: const {'vehicleId': 'vehicle-42'},
    );
    await tester.pumpAndSettle();
    expect(find.text('vehicle:vehicle-42'), findsOneWidget);

    router.pushNamed(
      AppRouteNames.workRegistration,
      pathParameters: const {'vehicleId': 'vehicle-42'},
    );
    await tester.pumpAndSettle();
    expect(find.text('new-work:vehicle-42'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    router.pushNamed(
      AppRouteNames.workDetail,
      pathParameters: const {'vehicleId': 'vehicle-42', 'workId': 'work-7'},
    );
    await tester.pumpAndSettle();
    expect(find.text('work:vehicle-42:work-7'), findsOneWidget);
  });
}

GoRouter _createRouter(ValueNotifier<AuthNavigationStatus> authStatus) {
  return createAppRouter(
    dependencies: AppRouterDependencies(
      authStatus: () => authStatus.value,
      authRefreshListenable: authStatus,
      splash: (_) => const Text('splash'),
      login: (_) => const Text('login'),
      registration: (_) => const Text('registration'),
      emailVerification: (_) => const Text('verify-email'),
      workshop: (_) => const _CounterProbe(),
      subscription: (_) => const Text('subscription'),
      vehicleConfiguration: (_, vehicleId) => Text('vehicle:$vehicleId'),
      workRegistration: (_, vehicleId) => Text('new-work:$vehicleId'),
      workDetail: (_, vehicleId, workId) => Text('work:$vehicleId:$workId'),
    ),
  );
}

class _CounterProbe extends StatelessWidget {
  const _CounterProbe();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('workshop'),
        TextField(key: Key('workshop-draft')),
      ],
    );
  }
}
