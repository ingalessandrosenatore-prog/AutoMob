import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/notifications/data/datasources/mechanic_notification_data_source.dart';
import '../../features/notifications/data/repositories/mechanic_notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/mechanic_notification_repository.dart';
import '../../features/notifications/domain/usecases/send_mechanic_notification.dart';

void registerNotificationDependencies(GetIt getIt, SupabaseClient client) {
  getIt
    ..registerLazySingleton<MechanicNotificationDataSource>(
      () => SupabaseMechanicNotificationDataSource(client),
    )
    ..registerLazySingleton<MechanicNotificationRepository>(
      () => MechanicNotificationRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => SendMechanicNotification(getIt()));
}
