import 'package:auto_mob_v1/features/dashboard/presentation/pages/home_view.dart';
import 'package:auto_mob_v1/features/servizi/presentation/pages/servizi_page.dart';
import 'package:auto_mob_v1/features/work_log/presentation/pages/midify_item.dart';
import 'package:auto_mob_v1/features/work_log/presentation/pages/work_log_history_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_view.dart';
import '../../features/auth/presentation/pages/registration_view.dart';
import '../../features/settings/presentation/pages/settings_view.dart';
import '../../features/vehicle/presentation/pages/vehicle_registration_page.dart';
import '../../features/vehicle/presentation/widgets/km_update_pop_up.dart';
import '../../features/work_log/presentation/widgets/functional_pop_up.dart';
import '../../features/work_log/presentation/pages/work_log_wizard_page.dart';
import '../di/injection_container.dart' as di;
import '../types/enum_pop_up.dart';
import 'am_transition_page.dart';
import 'go_router_refresh_stream.dart';
import 'shell_scaffold.dart';

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // Istanza unica dell'AuthBloc (registrato come lazy singleton nel DI):
  // e' la sorgente di verita' per capire dove mandare l'utente.
  static final AuthBloc _auth = di.sl<AuthBloc>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    // Ogni cambio di stato dell'auth fa rivalutare la `redirect`.
    refreshListenable: GoRouterRefreshStream(_auth.stream),
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => const RegistrationView(),
      ),

      // indexedStack: tiene VIVE tutte e 3 le tab contemporaneamente (solo la
      // corrente e' visibile, le altre restano montate). Cambiare tab non
      // ricostruisce piu' la pagina da zero -> niente scatto entrando su
      // "Lavori" (prima ogni tab veniva smontata e il suo header liquid-glass
      // ricompilato), e lo scroll di ogni tab e' preservato.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => HomeView(
                  initialVehicleId: state.uri.queryParameters['vehicleId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/lavori',
                name: 'lavori',
                builder: (context, state) => const WorkLogHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/servizi',
                name: 'servizi',
                builder: (context, state) => const ServiziPage(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) =>
            AmFadeThroughPage(key: state.pageKey, child: const SettingsView()),
      ),

      GoRoute(
        path: '/addVeichle',
        name: 'aggiungi_veicolo',
        pageBuilder: (context, state) => AmFadeThroughPage(
          key: state.pageKey,
          child: const VehicleRegistrationPage(),
        ),
      ),

      GoRoute(
        path: '/addFunctional',
        name: 'aggiungi_Funzione',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final typeEnum = extra['type'] as EnumPopUp;
          final id = extra['id'] as String;
          final currentKm = (extra['currentKm'] as int?) ?? 0;
          return BottomSheetPageFunc(
            type: typeEnum,
            idVeicolo: id,
            currentKm: currentKm,
          );
        },
      ),

      GoRoute(
        path: '/work-log-wizard',
        name: 'aggiungi_lavoro',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AmFadeThroughPage(
            key: state.pageKey,
            child: WorkLogWizardPage(
              vehicleId: extra['vehicleId'] as String,
              currentKm: extra['currentKm'] as int,
            ),
          );
        },
      ),

      GoRoute(
        path: '/parts',
        name: 'parts',
        pageBuilder: (context, state) =>
            AmFadeThroughPage(key: state.pageKey, child: const Midifyitem()),
      ),

      GoRoute(
        path: '/updatePopUp',
        name: 'updateKm',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final currentKm = (extra?['currentKm'] as String?) ?? '0';
          final id = (extra?['id'] as String?) ?? '';
          return KmUpdatePopUp(vehicleId: id, currentKm: currentKm);
        },
      ),
    ],
  );

  /// Apre la dashboard dal tap su una notifica ricevuta.
  static Future<void> openNotification(Map<String, dynamic> data) async {
    // A cold start il messaggio FCM puo' arrivare mentre AuthBloc e GoRouter
    // stanno ancora mostrando lo splash. Aspettiamo la sessione e il primo
    // frame stabile: cosi' non proviamo ad aprire una route troppo presto.
    if (_auth.state is! AuthAuthenticated) {
      await _auth.stream.firstWhere((state) => state is AuthAuthenticated);
    }
    await WidgetsBinding.instance.endOfFrame;

    final category = data['type']?.toString();
    if (category == 'maintenance_kpi') {
      router.go('/lavori');
      return;
    }

    final vehicleId = data['vehicle_id']?.toString();
    if (vehicleId == null || vehicleId.isEmpty) {
      router.go('/home');
      return;
    }
    router.go(
      Uri(path: '/home', queryParameters: {'vehicleId': vehicleId}).toString(),
    );
  }

  /// In foreground FCM non mostra automaticamente il banner su Android.
  /// Mostriamo quindi uno SnackBar usando il navigator principale.
  static void showForegroundNotification({
    required String title,
    required String body,
  }) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text('$title\n$body')));
  }

  /// Unico punto che decide la navigazione legata all'auth.
  /// Ritorna la rotta verso cui reindirizzare, oppure `null` per restare
  /// dove si e'.
  static String? _guard(BuildContext context, GoRouterState state) {
    final s = _auth.state;
    final loc = state.uri.path;

    final atAuth = loc == '/login' || loc == '/registration';
    final atSplash = loc == '/splash';

    // Stati transitori: non forzo nulla. All'avvio resto sullo splash
    // (initialLocation), durante un login/logout resto sulla pagina
    // corrente che mostra spinner/errore via BlocBuilder.
    if (s is AuthInitial || s is AuthLoading || s is AuthError) {
      return null;
    }

    // Autenticato: se sono ancora su splash/login/registration vado a home.
    if (s is AuthAuthenticated) {
      return (atSplash || atAuth) ? '/home' : null;
    }

    // Non autenticato (AuthUnauthenticated / AuthLoggedOut):
    // se sono su login o registration resto, altrimenti torno al login.
    return atAuth ? null : '/login';
  }
}
