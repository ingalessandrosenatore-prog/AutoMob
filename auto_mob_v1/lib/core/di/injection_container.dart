import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_session.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/login_with_google.dart';
import '../../features/auth/domain/usecases/login_with_apple.dart';
import '../../features/auth/domain/usecases/signup_with_email.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/presentation/Bloc/authBloc.dart';

// Vehicle
import '../../features/vehicle/data/datasources/vehicle_draft_local_data_source.dart';
import '../../features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import '../../features/vehicle/data/repositories/vehicle_repository_impl.dart';
import '../../features/vehicle/domain/repositories/VehicleRepository.dart';
import '../../features/vehicle/domain/usecases/SaveDraftStep.dart';
import '../../features/vehicle/domain/usecases/SaveVehicle.dart';
import '../../features/vehicle/domain/usecases/GetVehicles.dart';
import '../../features/vehicle/presentation/provider/add_vehicle_bloc.dart';

// Dashboard
import '../../features/dashboard/presentation/Bloc/dashboardBloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await _initSupabase();
  await _initSharedPreferences();
  await _initAuth();
  await _initVehicle();
  await _initDashboard();
}

Future<void> _initSupabase() async {
  await Supabase.initialize(
    url: 'https://tvxcyjqaiyxmmhktwhdb.supabase.co',
    anonKey: 'sb_publishable_3lGoL7YRneTfCS5z-LIWiQ_ilPxOklI',
  );
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
}

Future<void> _initSharedPreferences() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
}

Future<void> _initAuth() async {
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      checkSession: sl(),
      loginWithEmail: sl(),
      loginWithGoogle: sl(),
      loginWithApple: sl(),
      signupWithEmail: sl(),
      logout: sl(),
    ),
  );

  sl.registerLazySingleton<CheckSession>(() => CheckSession(sl()));
  sl.registerLazySingleton<LoginWithEmail>(() => LoginWithEmail(sl()));
  sl.registerLazySingleton<LoginWithGoogle>(() => LoginWithGoogle(sl()));
  sl.registerLazySingleton<LoginWithApple>(() => LoginWithApple(sl()));
  sl.registerLazySingleton<SignupWithEmail>(() => SignupWithEmail(sl()));
  sl.registerLazySingleton<Logout>(() => Logout(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
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
    () => AddVehicleBloc(
      saveDraftStep: sl(),
      saveVehicle: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton<SaveDraftStep>(() => SaveDraftStep(sl()));
  sl.registerLazySingleton<SaveVehicle>(() => SaveVehicle(sl()));
  sl.registerLazySingleton<GetVehicles>(() => GetVehicles(sl()));

  // Repository
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<VehicleDraftLocalDataSource>(
    () => VehicleDraftLocalDataSourceImpl(sl(), dirPAth: cartellaFoto.path),
  );
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(supabaseClient: sl()),
  );
}

Future<void> _initDashboard() async {
  // BLoC — factory: nuova istanza ad ogni apertura della home.
  // Riusa GetVehicles della feature vehicle (domain shared via use case).
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(getVehicles: sl()),
  );
}
