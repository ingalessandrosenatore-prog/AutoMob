import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/theme_cubit.dart';
import '../theme/theme_preferences.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_session.dart';
import '../../features/auth/domain/usecases/get_pending_verification_email.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/login_with_google.dart';
import '../../features/auth/domain/usecases/login_with_apple.dart';
import '../../features/auth/domain/usecases/signup_with_email.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/leave_email_verification.dart';
import '../../features/auth/domain/usecases/observe_authenticated_users.dart';
import '../../features/auth/domain/usecases/resend_confirmation_email.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Notifications
import '../../features/notifications/data/datasources/firebase_messaging_data_source.dart';
import '../../features/notifications/data/datasources/notification_local_data_source.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/observe_notification_messages.dart';
import '../../features/notifications/domain/usecases/postpone_notification_permission.dart';
import '../../features/notifications/domain/usecases/register_device_token.dart';
import '../../features/notifications/domain/usecases/request_notification_permission.dart';
import '../../features/notifications/domain/usecases/should_offer_notification_permission.dart';
import '../../features/notifications/domain/usecases/unregister_device_token.dart';
import '../../features/notifications/presentation/services/notification_message_coordinator.dart';

// Vehicle
import '../../features/vehicle/data/datasources/vehicle_draft_local_data_source.dart';
import '../../features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import '../../features/vehicle/data/datasources/vehicle_lookup_remote_data_source.dart';
import '../../features/vehicle/data/repositories/vehicle_repository_impl.dart';
import '../../features/vehicle/data/repositories/vehicle_lookup_repository_impl.dart';
import '../../features/vehicle/domain/repositories/vehicle_repository.dart';
import '../../features/vehicle/domain/repositories/vehicle_lookup_repository.dart';
import '../../features/vehicle/domain/usecases/save_draft_step.dart';
import '../../features/vehicle/domain/usecases/save_vehicle.dart';
import '../../features/vehicle/domain/usecases/get_vehicles.dart';
import '../../features/vehicle/domain/usecases/update_vehicle_km.dart';
import '../../features/vehicle/domain/usecases/update_vehicle_revision.dart';
import '../../features/vehicle/domain/usecases/update_vehicle_photo.dart';
import '../../features/vehicle/domain/usecases/compute_maintenance_kpis.dart';
import '../../features/vehicle/domain/usecases/lookup_vehicle_by_plate.dart';
import '../../features/vehicle/domain/usecases/lookup_mechanic_by_code.dart';
import '../../features/vehicle/domain/usecases/load_vehicle_draft.dart';
import '../../features/vehicle/domain/usecases/clear_vehicle_draft.dart';
import '../../features/vehicle/domain/usecases/connect_mechanic.dart';
import '../../features/vehicle/presentation/bloc/add_vehicle_bloc.dart';
import '../../features/vehicle/presentation/bloc/km_update_cubit.dart';
import '../../features/vehicle/presentation/bloc/revision_update_cubit.dart';
import '../../features/vehicle/presentation/bloc/vehicle_registration_bloc.dart';

// Dashboard
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/bloc/connect_mechanic_cubit.dart';
import '../../features/dashboard/presentation/bloc/notification_prompt_bloc.dart';

// WorkLog
import '../../features/work_log/data/datasources/worklog_remote_data_source.dart';
import '../../features/work_log/data/repositories/worklog_repository_impl.dart';
import '../../features/work_log/domain/repositories/worklog_repo.dart';
import '../../features/work_log/domain/usecases/create_work_log.dart';
import '../../features/work_log/domain/usecases/get_vehicle_options.dart';
import '../../features/work_log/domain/usecases/get_vehicle_works.dart';
import '../../features/work_log/presentation/bloc/work_log_bloc.dart';
import '../../features/work_log/presentation/bloc/work_log_history_bloc.dart';

final sl = GetIt.instance;

Future<void> init({bool firebaseAvailable = false}) async {
  await _initSupabase();
  await _initSharedPreferences();
  _initTheme();
  _initNotifications(firebaseAvailable: firebaseAvailable);
  await _initAuth();
  await _initVehicle();
  await _initDashboard();
  _initWorkLog();
}

void _initNotifications({required bool firebaseAvailable}) {
  sl.registerLazySingleton<FirebaseMessagingDataSource>(
    () => FirebaseMessagingDataSourceImpl(firebaseAvailable: firebaseAvailable),
  );
  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () =>
        NotificationRepositoryImpl(messaging: sl(), local: sl(), remote: sl()),
  );

  sl.registerLazySingleton<ShouldOfferNotificationPermission>(
    () => ShouldOfferNotificationPermission(sl()),
  );
  sl.registerLazySingleton<RequestNotificationPermission>(
    () => RequestNotificationPermission(sl()),
  );
  sl.registerLazySingleton<PostponeNotificationPermission>(
    () => PostponeNotificationPermission(sl()),
  );
  sl.registerLazySingleton<RegisterDeviceToken>(
    () => RegisterDeviceToken(sl()),
  );
  sl.registerLazySingleton<UnregisterDeviceToken>(
    () => UnregisterDeviceToken(sl()),
  );
  sl.registerLazySingleton<ObserveNotificationMessages>(
    () => ObserveNotificationMessages(sl()),
  );
  sl.registerLazySingleton<NotificationMessageCoordinator>(
    () => NotificationMessageCoordinator(
      messages: sl(),
      registerDeviceToken: sl(),
    ),
    dispose: (coordinator) => coordinator.dispose(),
  );
}

Future<void> _initSupabase() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || publishableKey.isEmpty) {
    throw StateError(
      'Configurazione Supabase assente. Avvia con '
      '--dart-define-from-file=.env (vedi .env.example).',
    );
  }
  await Supabase.initialize(url: url, publishableKey: publishableKey);
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
}

Future<void> _initSharedPreferences() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
}

void _initTheme() {
  sl.registerLazySingleton<ThemePreferences>(() => ThemePreferences(sl()));
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(sl()),
    dispose: (cubit) => cubit.close(),
  );
}

Future<void> _initAuth() async {
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      checkSession: sl(),
      getPendingVerificationEmail: sl(),
      loginWithEmail: sl(),
      loginWithGoogle: sl(),
      loginWithApple: sl(),
      signupWithEmail: sl(),
      logout: sl(),
      resendConfirmationEmail: sl(),
      leaveEmailVerification: sl(),
      observeAuthenticatedUsers: sl(),
    ),
  );

  sl.registerLazySingleton<CheckSession>(() => CheckSession(sl()));
  sl.registerLazySingleton<GetPendingVerificationEmail>(
    () => GetPendingVerificationEmail(sl()),
  );
  sl.registerLazySingleton<LoginWithEmail>(() => LoginWithEmail(sl()));
  sl.registerLazySingleton<LoginWithGoogle>(() => LoginWithGoogle(sl()));
  sl.registerLazySingleton<LoginWithApple>(() => LoginWithApple(sl()));
  sl.registerLazySingleton<SignupWithEmail>(() => SignupWithEmail(sl()));
  sl.registerLazySingleton<Logout>(() => Logout(sl()));
  sl.registerLazySingleton<ResendConfirmationEmail>(
    () => ResendConfirmationEmail(sl()),
  );
  sl.registerLazySingleton<LeaveEmailVerification>(
    () => LeaveEmailVerification(sl()),
  );
  sl.registerLazySingleton<ObserveAuthenticatedUsers>(
    () => ObserveAuthenticatedUsers(sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      beforeLogout: () async {
        // Il token va disattivato mentre il JWT dell'utente e' ancora valido.
        await sl<UnregisterDeviceToken>()();
      },
    ),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl()),
  );
}

Future<void> _initVehicle() async {
  final appDir = await getApplicationDocumentsDirectory();
  final cartellaFoto = Directory('${appDir.path}/foto_veicoli');
  if (!await cartellaFoto.exists()) {
    await cartellaFoto.create(recursive: true);
  }

  // BLoC — factory: nuova istanza ad ogni apertura del wizard
  sl.registerFactory<AddVehicleBloc>(
    () => AddVehicleBloc(saveDraftStep: sl(), saveVehicle: sl()),
  );

  // Use Cases
  sl.registerLazySingleton<SaveDraftStep>(() => SaveDraftStep(sl()));
  sl.registerLazySingleton<SaveVehicle>(() => SaveVehicle(sl()));
  sl.registerLazySingleton<LoadVehicleDraft>(() => LoadVehicleDraft(sl()));
  sl.registerLazySingleton<ClearVehicleDraft>(() => ClearVehicleDraft(sl()));
  sl.registerLazySingleton<GetVehicles>(() => GetVehicles(sl()));
  sl.registerLazySingleton<UpdateVehicleKm>(() => UpdateVehicleKm(sl()));
  sl.registerLazySingleton<UpdateVehicleRevision>(
    () => UpdateVehicleRevision(sl()),
  );
  sl.registerLazySingleton<UpdateVehiclePhoto>(() => UpdateVehiclePhoto(sl()));
  sl.registerLazySingleton<ConnectMechanic>(() => ConnectMechanic(sl()));

  // Cubit modale "Aggiorna KM" — factory: nuova istanza ad ogni apertura.
  sl.registerFactory<KmUpdateCubit>(() => KmUpdateCubit(sl()));
  sl.registerFactory<RevisionUpdateCubit>(() => RevisionUpdateCubit(sl()));
  sl.registerFactory<ConnectMechanicCubit>(() => ConnectMechanicCubit(sl()));

  // Repository
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(localDataSource: sl(), remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<VehicleDraftLocalDataSource>(
    () => VehicleDraftLocalDataSourceImpl(sl(), dirPAth: cartellaFoto.path),
  );
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Registrazione veicolo — pagina full-screen (rework da pop-up), solo
  // front-end per ora: lookup targa mock, nessun salvataggio reale.
  sl.registerFactory<VehicleRegistrationBloc>(
    () => VehicleRegistrationBloc(
      lookupVehicleByPlate: sl(),
      lookupMechanicByCode: sl(),
      saveDraftStep: sl(),
      loadVehicleDraft: sl(),
      clearVehicleDraft: sl(),
      saveVehicle: sl(),
    ),
  );
  sl.registerLazySingleton<LookupVehicleByPlate>(
    () => LookupVehicleByPlate(sl()),
  );
  sl.registerLazySingleton<LookupMechanicByCode>(
    () => LookupMechanicByCode(sl()),
  );
  sl.registerLazySingleton<VehicleLookupRepository>(
    () => VehicleLookupRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<VehicleLookupRemoteDataSource>(
    () => VehicleLookupRemoteDataSourceImpl(sl()),
  );
}

Future<void> _initDashboard() async {
  // Use case di calcolo KPI: logica pura, nessuna dipendenza -> singleton.
  sl.registerLazySingleton<ComputeMaintenanceKpis>(
    () => ComputeMaintenanceKpis(),
  );

  // BLoC — lazySingleton: la stessa istanza sopravvive ai cambi di tab, cosi'
  // i dati restano in cache e non si ricaricano ad ogni apertura della home
  // (il caricamento vero riparte solo se lo stato e' ancora Initial/Error —
  // vedi guard in home_view.dart). Resettato al logout in main.dart.
  // Riusa GetVehicles della feature vehicle (domain shared via use case).
  sl.registerLazySingleton<DashboardBloc>(
    () => DashboardBloc(
      getVehicles: sl(),
      computeKpis: sl(),
      updateVehiclePhoto: sl(),
    ),
    dispose: (b) => b.close(),
  );

  // Coordinatore presentation locale alla Home: nuova istanza ad ogni mount.
  // Usa soltanto i use case pubblici della feature notifications.
  sl.registerFactory<NotificationPromptBloc>(
    () => NotificationPromptBloc(
      shouldOfferPermission: sl(),
      requestPermission: sl(),
      postponePermission: sl(),
      registerDeviceToken: sl(),
    ),
  );
}

void _initWorkLog() {
  // Data Source
  sl.registerLazySingleton<WorklogRemoteDataSource>(
    () => WorklogRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<WorklogRepo>(
    () => WorklogRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Case
  sl.registerLazySingleton<CreateWorkLog>(() => CreateWorkLog(sl()));
  sl.registerLazySingleton<GetVehicleOptions>(() => GetVehicleOptions(sl()));
  sl.registerLazySingleton<GetVehicleWorks>(() => GetVehicleWorks(sl()));

  // BLoC — factory con param (vehicleId passato dal popup all'apertura)
  sl.registerFactoryParam<WorkLogBloc, String, void>(
    (vehicleId, _) => WorkLogBloc(createWorkLog: sl(), vehicleId: vehicleId),
  );

  // BLoC storico — lazySingleton: stessa logica di DashboardBloc sopra,
  // cache tra le visite della pagina, guard su Initial/Error, reset al logout.
  sl.registerLazySingleton<WorkLogHistoryBloc>(
    () => WorkLogHistoryBloc(getVehicleOptions: sl(), getVehicleWorks: sl()),
    dispose: (b) => b.close(),
  );
}
