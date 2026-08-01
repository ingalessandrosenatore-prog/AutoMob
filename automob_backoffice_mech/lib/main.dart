import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/app_router_dependencies.dart';
import 'core/router/app_route_paths.dart';
import 'core/router/auth_router_refresh_notifier.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/registration_wizard_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || publishableKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY sono obbligatori.',
    );
  }
  await Supabase.initialize(url: url, publishableKey: publishableKey);
  await configureDependencies();
  runApp(MainApp(authBloc: getIt<AuthBloc>()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AuthRouterRefreshNotifier _authRefresh;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRefresh = AuthRouterRefreshNotifier(widget.authBloc);
    _router = createAppRouter(
      dependencies: AppRouterDependencies(
        authStatus: () => _authRefresh.status,
        authRefreshListenable: _authRefresh,
        splash: (_) => const SplashPage(),
        login: (context) => LoginPage(
          onRegistrationPressed: () => context.go(AppRoutePaths.registration),
        ),
        registration: (_) => const RegistrationWizardPage(),
        emailVerification: (_) => const RegistrationWizardPage(),
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
    _authRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.authBloc,
      child: MaterialApp.router(
        title: 'AutoMob Meccanico',
        theme: AmTheme.light,
        darkTheme: AmTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

Widget _emptyRoute(BuildContext context) => const SizedBox.shrink();
