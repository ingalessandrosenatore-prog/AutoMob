import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'core/di/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import 'features/work_log/presentation/bloc/work_log_history_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {}
  }

  await di.init();
  runApp(const AutoMobApp());
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
        // BlocProvider<WorkLogBloc>(...),
      ],
      // DashboardBloc/WorkLogHistoryBloc sono lazySingleton (cache dati tra
      // i cambi di tab, vedi injection_container.dart): senza questo reset
      // sopravvivrebbero al logout, mostrando i dati del vecchio utente a
      // chi fa login dopo sullo stesso device. `listenWhen` richiede una
      // vera transizione autenticato -> sloggato, cosi' il cold-boot
      // (AuthInitial -> AuthUnauthenticated, nessun login ancora avvenuto)
      // non spreca un reset inutile.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous is AuthAuthenticated &&
            (current is AuthLoggedOut || current is AuthUnauthenticated),
        listener: (_, _) {
          di.sl.resetLazySingleton<DashboardBloc>();
          di.sl.resetLazySingleton<WorkLogHistoryBloc>();
        },
        child: MaterialApp.router(
          title: 'AutoMob',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
