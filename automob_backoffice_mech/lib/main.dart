import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/app_router_dependencies.dart';
import 'core/router/app_route_names.dart';
import 'core/router/app_route_paths.dart';
import 'core/router/auth_router_refresh_notifier.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/domain/usecases/send_mechanic_notification.dart';
import 'features/notifications/presentation/bloc/mechanic_notification_cubit.dart';
import 'features/notifications/presentation/widgets/mechanic_notification_dialog.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/registration_wizard_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/settings/presentation/cubit/theme_mode_cubit.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/subscription/domain/entities/subscription_overview.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';
import 'features/subscription/presentation/bloc/subscription_event.dart';
import 'features/subscription/presentation/pages/subscription_page.dart';
import 'features/subscription/presentation/pages/subscription_plan_page.dart';
import 'features/subscription/presentation/pages/workshop_profile_page.dart';
import 'features/service_requests/presentation/bloc/service_requests_cubit.dart';
import 'features/service_requests/presentation/pages/service_requests_page.dart';
import 'features/workshop/presentation/pages/workshop_home_page.dart';
import 'features/workshop/presentation/pages/mechanic_work_log_detail_page.dart';
import 'features/workshop/presentation/pages/mechanic_work_log_wizard_page.dart';
import 'package:automob_work_log/automob_work_log.dart';
import 'features/workshop/presentation/bloc/workshop_bloc.dart';
import 'features/workshop/presentation/bloc/workshop_overview_cubit.dart';
import 'features/workshop/presentation/bloc/workshop_event.dart';
import 'features/workshop/presentation/bloc/voice_search_bloc.dart';

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
  late final ThemeModeCubit _themeModeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRefresh = AuthRouterRefreshNotifier(widget.authBloc);
    _themeModeCubit = ThemeModeCubit();
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
        workshop: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: getIt<WorkshopBloc>()..add(const WorkshopStarted()),
            ),
            BlocProvider(create: (_) => getIt<VoiceSearchBloc>()),
            BlocProvider(create: (_) => getIt<WorkshopOverviewCubit>()),
          ],
          child: WorkshopHomePage(
            onSettingsPressed: () => context.pushNamed(AppRouteNames.settings),
          ),
        ),
        settings: (_) => const SettingsPage(),
        subscription: (_) => BlocProvider(
          create: (_) =>
              getIt<SubscriptionBloc>()..add(const SubscriptionStarted()),
          child: const SubscriptionPage(),
        ),
        serviceRequests: (_) => BlocProvider(
          create: (_) => getIt<ServiceRequestsCubit>()..load(),
          child: const ServiceRequestsPage(),
        ),
        subscriptionPlan: (_, extra) => SubscriptionPlanPage(
          currentOverview: extra is SubscriptionOverview ? extra : null,
        ),
        workshopProfile: (_) => const WorkshopProfilePage(),
        vehicleConfiguration: (context, vehicleId, extra) {
          final launch = switch (extra) {
            MechanicWorkLogLaunch launch => launch,
            WorkLogLaunchContext context => MechanicWorkLogLaunch(
              vehicle: WorkLogVehicle(
                id: context.vehicleId,
                name: context.vehicleName,
                plate: '',
                currentKm: context.currentKm,
              ),
            ),
            _ => MechanicWorkLogLaunch(
              vehicle: WorkLogVehicle(
                id: vehicleId,
                name: 'Storico lavori',
                plate: '',
                currentKm: 0,
              ),
            ),
          };
          return WorkLogFeature(
            launch: launch,
            onNotificationsPressed: () => showMechanicNotificationDialog(
              context,
              vehicleName: [
                launch.vehicle.name,
                launch.vehicle.plate,
              ].where((value) => value.isNotEmpty).join(' · '),
              createCubit: () => MechanicNotificationCubit(
                sendNotification: getIt<SendMechanicNotification>(),
                vehicleId: launch.vehicle.id,
              ),
            ),
            dependencies: WorkLogDependencies(
              repository: getIt<WorkLogRepository>(),
            ),
          );
        },
        workRegistration: (_, vehicleId, extra) => MechanicWorkLogWizardPage(
          workLogContext: extra is WorkLogLaunchContext
              ? extra
              : WorkLogLaunchContext(
                  vehicleId: vehicleId,
                  vehicleName: 'Veicolo',
                  currentKm: 0,
                ),
          cubit: getIt<WorkLogEditorCubit>(),
        ),
        workDetail: (_, vehicleId, workId, extra) => extra is WorkLogEntry
            ? MechanicWorkLogDetailPage(entry: extra)
            : Scaffold(
                appBar: AppBar(),
                body: const Center(child: Text('Lavoro non disponibile')),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _themeModeCubit.close();
    _authRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.authBloc),
        BlocProvider.value(value: _themeModeCubit),
      ],
      child: BlocBuilder<ThemeModeCubit, bool>(
        builder: (context, isDarkMode) => MaterialApp.router(
          title: 'AutoMob Meccanico',
          theme: AmTheme.light,
          darkTheme: AmTheme.dark,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: _router,
        ),
      ),
    );
  }
}
