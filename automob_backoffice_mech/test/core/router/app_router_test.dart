import 'package:automob_backoffice_mech/core/router/app_route_names.dart';
import 'package:automob_backoffice_mech/core/router/app_router.dart';
import 'package:automob_backoffice_mech/core/router/app_router_dependencies.dart';
import 'package:automob_backoffice_mech/core/router/auth_navigation_status.dart';
import 'package:automob_backoffice_mech/core/router/mechanic_shell_metrics.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

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

    await tester.pumpWidget(
      MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);

    authStatus.value = AuthNavigationStatus.authenticated;
    await tester.pumpAndSettle();

    expect(find.text('workshop'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Servizi'), findsOneWidget);
    expect(find.text('Richieste'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('mechanic_bottom_navigation')))
          .height,
      MechanicShellMetrics.navigationHeight,
    );
    final navigationRect = tester.getRect(
      find.byKey(const ValueKey('mechanic_bottom_navigation')),
    );
    final publishedBottom = tester
        .getSize(find.byKey(const ValueKey('mechanic_shell_bottom_inset')))
        .height;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(navigationRect.bottom + publishedBottom, screenHeight);
    expect(find.byType(OCLiquidGlass), findsOneWidget);

    expect(find.byType(AmNavigationGlow), findsOneWidget);
    final glow = tester.widget<AmNavigationGlow>(find.byType(AmNavigationGlow));
    expect(glow.width, greaterThan(glow.height));
    expect(glow.height, MechanicShellMetrics.navigationHeight - 12);
    final surface = find.descendant(
      of: find.byType(AmNavigationGlow),
      matching: find.byType(DecoratedBox),
    );
    final before = tester.getRect(surface);
    await tester.tap(find.text('Servizi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final during = tester.getRect(surface);
    await tester.pumpAndSettle();
    final after = tester.getRect(surface);
    expect(during.left, greaterThan(before.left));
    expect(during.left, lessThan(after.left));
    expect(after.width, closeTo(before.width, 0.01));
    expect(after.height, closeTo(before.height, 0.01));

    await tester.tap(find.text('Richieste'));
    await tester.pumpAndSettle();
    expect(find.text('service-requests'), findsOneWidget);
  });

  testWidgets('switching tabs preserves the workshop state', (tester) async {
    final authStatus = ValueNotifier(AuthNavigationStatus.authenticated);
    final router = _createRouter(authStatus);
    addTearDown(() {
      router.dispose();
      authStatus.dispose();
    });

    await tester.pumpWidget(
      MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('workshop-draft')),
      'bozza mantenuta',
    );

    await tester.tap(find.text('Servizi'));
    await tester.pumpAndSettle();
    expect(find.text('subscription'), findsOneWidget);

    await tester.tap(find.text('Home'));
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

      await tester.pumpWidget(
        MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
      );
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

    await tester.pumpWidget(
      MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
    );
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

  testWidgets('settings apre una pagina root e torna alla Home', (
    tester,
  ) async {
    final authStatus = ValueNotifier(AuthNavigationStatus.authenticated);
    final router = _createRouter(authStatus);
    addTearDown(() {
      router.dispose();
      authStatus.dispose();
    });

    await tester.pumpWidget(
      MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();

    router.pushNamed(AppRouteNames.settings);
    await tester.pumpAndSettle();
    expect(find.text('settings'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('workshop'), findsOneWidget);
  });

  testWidgets('subscription cards have dedicated detail routes', (
    tester,
  ) async {
    final authStatus = ValueNotifier(AuthNavigationStatus.authenticated);
    final router = _createRouter(authStatus);
    addTearDown(() {
      router.dispose();
      authStatus.dispose();
    });

    await tester.pumpWidget(
      MaterialApp.router(theme: AmTheme.dark, routerConfig: router),
    );
    await tester.pumpAndSettle();

    router.pushNamed(AppRouteNames.subscriptionPlan);
    await tester.pumpAndSettle();
    expect(find.text('subscription-plan'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    router.pushNamed(AppRouteNames.workshopProfile);
    await tester.pumpAndSettle();
    expect(find.text('workshop-profile'), findsOneWidget);
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
      settings: (_) => const Text('settings'),
      subscription: (_) => const Text('subscription'),
      serviceRequests: (_) => const Text('service-requests'),
      subscriptionPlan: (_, _) => const Text('subscription-plan'),
      workshopProfile: (_) => const Text('workshop-profile'),
      vehicleConfiguration: (_, vehicleId, _) => Text('vehicle:$vehicleId'),
      workRegistration: (_, vehicleId, _) => Text('new-work:$vehicleId'),
      workDetail: (_, vehicleId, workId, _) => Text('work:$vehicleId:$workId'),
    ),
  );
}

class _CounterProbe extends StatelessWidget {
  const _CounterProbe();

  @override
  Widget build(BuildContext context) {
    final shellBottom = MechanicShellGeometry.of(context).controlsBottom;
    return Column(
      children: [
        SizedBox(
          key: const ValueKey('mechanic_shell_bottom_inset'),
          height: shellBottom,
        ),
        const Text('workshop'),
        const TextField(key: Key('workshop-draft')),
      ],
    );
  }
}
