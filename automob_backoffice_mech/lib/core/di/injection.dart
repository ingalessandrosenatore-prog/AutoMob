import 'package:get_it/get_it.dart';
import 'package:automob_work_log/automob_work_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_injection.dart';
import '../../features/workshop/data/datasources/workshop_overview_demo_data_source.dart';
import '../../features/workshop/data/repositories/workshop_overview_repository_impl.dart';
import '../../features/workshop/domain/repositories/workshop_overview_repository.dart';
import '../../features/workshop/domain/usecases/get_workshop_overview.dart';
import '../../features/workshop/presentation/bloc/workshop_overview_cubit.dart';
import '../../features/service_requests/data/datasources/service_request_remote_data_source.dart';
import '../../features/service_requests/data/repositories/service_request_repository_impl.dart';
import '../../features/service_requests/domain/repositories/service_request_repository.dart';
import '../../features/service_requests/domain/usecases/get_service_requests.dart';
import '../../features/service_requests/presentation/bloc/service_requests_cubit.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/municipality_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_auth_session.dart';
import '../../features/auth/domain/usecases/get_italian_municipalities.dart';
import '../../features/auth/domain/usecases/get_pending_verification_email.dart';
import '../../features/auth/domain/usecases/login_with_email.dart';
import '../../features/auth/domain/usecases/register_mechanic.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/subscription/data/datasources/subscription_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/get_subscription_overview.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';
import '../../features/workshop/data/datasources/workshop_remote_data_source.dart';
import '../../features/workshop/data/datasources/speech_recognition_data_source.dart';
import '../../features/workshop/data/repositories/voice_recognition_repository_impl.dart';
import '../../features/workshop/data/repositories/workshop_repository_impl.dart';
import '../../features/workshop/domain/repositories/voice_recognition_repository.dart';
import '../../features/workshop/domain/repositories/workshop_repository.dart';
import '../../features/workshop/domain/usecases/get_workshop_catalog.dart';
import '../../features/workshop/domain/usecases/start_voice_recognition.dart';
import '../../features/workshop/domain/usecases/stop_voice_recognition.dart';
import '../../features/workshop/presentation/bloc/voice_search_bloc.dart';
import '../../features/workshop/presentation/bloc/workshop_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  registerNotificationDependencies(getIt, Supabase.instance.client);
  final preferences = await SharedPreferences.getInstance();
  getIt
    ..registerLazySingleton<ServiceRequestRemoteDataSource>(
      () => SupabaseServiceRequestRemoteDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<ServiceRequestRepository>(
      () => ServiceRequestRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetServiceRequests(getIt()))
    ..registerFactory(() => ServiceRequestsCubit(getIt()))
    ..registerLazySingleton(WorkshopOverviewDemoDataSource.new)
    ..registerLazySingleton<WorkshopOverviewRepository>(
      () => WorkshopOverviewRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetWorkshopOverview(getIt()))
    ..registerFactory(() => WorkshopOverviewCubit(getIt()))
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<MunicipalityLocalDataSource>(
      MunicipalityLocalDataSourceImpl.new,
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Supabase.instance.client),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: getIt(),
        localDataSource: getIt(),
        municipalityDataSource: getIt(),
      ),
    )
    ..registerLazySingleton(() => RegisterMechanic(getIt()))
    ..registerLazySingleton(() => LoginWithEmail(getIt()))
    ..registerLazySingleton(() => CheckAuthSession(getIt()))
    ..registerLazySingleton(() => GetPendingVerificationEmail(getIt()))
    ..registerLazySingleton(() => GetItalianMunicipalities(getIt()))
    ..registerLazySingleton<SubscriptionDataSource>(
      () => SupabaseSubscriptionDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetSubscriptionOverview(getIt()))
    ..registerFactory(() => SubscriptionBloc(getSubscriptionOverview: getIt()))
    ..registerLazySingleton<WorkshopRemoteDataSource>(
      () => SupabaseWorkshopRemoteDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<WorkshopRepository>(
      () => WorkshopRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetWorkshopCatalog(getIt()))
    ..registerFactory(SpeechToText.new)
    ..registerFactory<SpeechRecognitionDataSource>(
      () => DeviceSpeechRecognitionDataSource(getIt()),
    )
    ..registerFactory<VoiceRecognitionRepository>(
      () => VoiceRecognitionRepositoryImpl(getIt()),
    )
    ..registerFactory(() => StartVoiceRecognition(getIt()))
    ..registerFactory(() => StopVoiceRecognition(getIt()))
    ..registerFactory(
      () => VoiceSearchBloc(
        startVoiceRecognition: getIt(),
        stopVoiceRecognition: getIt(),
      ),
    )
    ..registerLazySingleton<WorkLogRemoteDataSource>(
      () => SupabaseWorkLogRemoteDataSource(Supabase.instance.client),
    )
    ..registerLazySingleton<WorkLogRepository>(
      () => WorkLogRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetVehicleWorkHistory(getIt()))
    ..registerFactory(() => WorkLogHistoryBloc(getVehicleWorkHistory: getIt()))
    ..registerLazySingleton(() => CreateWorkLog(getIt()))
    ..registerFactory(() => WorkLogEditorCubit(createWorkLog: getIt()))
    ..registerLazySingleton(() => WorkshopBloc(getWorkshopCatalog: getIt()))
    ..registerSingleton<AuthBloc>(
      AuthBloc(
        loginWithEmail: getIt(),
        registerMechanic: getIt(),
        checkAuthSession: getIt(),
        getPendingVerificationEmail: getIt(),
        getItalianMunicipalities: getIt(),
      )..add(const AuthStarted()),
    );
}
