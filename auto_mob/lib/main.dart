import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:auto_mob_v1/core/di/injection_container.dart' as di;
import 'package:auto_mob_v1/core/router/app_router.dart';
import 'package:auto_mob_v1/core/theme/am_theme.dart';
import 'package:auto_mob_v1/core/theme/am_theme_mode.dart';
import 'package:auto_mob_v1/core/theme/theme_cubit.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:auto_mob_v1/features/auth/presentation/bloc/auth_state.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:auto_mob_v1/features/notifications/data/datasources/firebase_bootstrap.dart';
import 'package:auto_mob_v1/features/notifications/presentation/services/notification_message_coordinator.dart';
import 'package:auto_mob_v1/features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_history_bloc.dart';
import 'package:auto_mob_v1/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Il processo background puo' essere avviato quando l'app non e' in memoria.
  // Firebase deve quindi essere inizializzato anche qui.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }

  final firebaseAvailable = await FirebaseBootstrap.initialize();
  if (firebaseAvailable) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await di.init(firebaseAvailable: firebaseAvailable);
  runApp(const AutoMobApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    di.sl<NotificationMessageCoordinator>().start(
      onOpened: (data, _, _) => AppRouter.openNotification(data),
      onForeground: (_, title, body) {
        AppRouter.showForegroundNotification(
          title: title ?? 'AutoMob',
          body: body ?? 'Hai un nuovo promemoria.',
        );
      },
    );
  });
}

class AutoMobApp extends StatelessWidget {
  const AutoMobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: di.sl<AuthBloc>()),
        // Altri BLoC saranno aggiunti qui quando implementeremo le altre feature
        // BlocProvider<DashboardBloc>(...),
        BlocProvider<AddVehicleBloc>.value(value: di.sl<AddVehicleBloc>()),
        BlocProvider<ThemeCubit>.value(value: di.sl<ThemeCubit>()),
        // BlocProvider<WorkLogBloc>(...),
      ],
      // DashboardBloc/WorkLogHistoryBloc sono lazySingleton (cache dati tra
      // i cambi di tab, vedi injection_container.dart): senza questo reset
      // sopravvivrebbero al logout, mostrando i dati del vecchio utente a
      // chi fa login dopo sullo stesso device.
      // NB: AuthBloc._onLogout emette AuthLoading() PRIMA di AuthLoggedOut(),
      // quindi lo stato immediatamente precedente a AuthLoggedOut e' sempre
      // AuthLoading, mai AuthAuthenticated: un guard su `previous` si
      // perderebbe la transizione vera. Si reagisce solo su `current`.
      // Nessun rischio di reset superfluo: resetLazySingleton su un
      // singleton mai istanziato (es. cold-boot) e' un no-op sicuro.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, current) =>
            current is AuthLoggedOut || current is AuthUnauthenticated,
        listener: (_, _) {
          di.sl.resetLazySingleton<DashboardBloc>();
          di.sl.resetLazySingleton<WorkLogHistoryBloc>();
        },
        child: BlocBuilder<ThemeCubit, AmThemeMode>(
          builder: (context, themeMode) => MaterialApp.router(
            title: 'AutoMob',
            theme: AmTheme.light,
            darkTheme: AmTheme.dark,
            themeMode: themeMode == AmThemeMode.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}
