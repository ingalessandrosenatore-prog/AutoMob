import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/router/app_router_dependencies.dart';
import 'core/router/auth_navigation_status.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final ValueNotifier<AuthNavigationStatus> _authStatus;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authStatus = ValueNotifier(AuthNavigationStatus.unauthenticated);
    _router = createAppRouter(
      dependencies: AppRouterDependencies(
        authStatus: () => _authStatus.value,
        authRefreshListenable: _authStatus,
        splash: _emptyRoute,
        login: _emptyRoute,
        registration: _emptyRoute,
        emailVerification: _emptyRoute,
        workshop: _emptyRoute,
        subscription: _emptyRoute,
        vehicleConfiguration: (_, _) => const SizedBox.shrink(),
        workRegistration: (_, _) => const SizedBox.shrink(),
        workDetail: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _authStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AutoMob Meccanico',
      theme: AmTheme.light,
      darkTheme: AmTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

Widget _emptyRoute(BuildContext context) => const SizedBox.shrink();
