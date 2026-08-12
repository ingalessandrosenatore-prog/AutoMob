import 'work_log_repository.dart';
import 'work_log_vehicle.dart';

sealed class WorkLogLaunch {
  const WorkLogLaunch();
}

final class OwnerWorkLogLaunch extends WorkLogLaunch {
  const OwnerWorkLogLaunch({this.initialVehicleId});

  final String? initialVehicleId;
}

final class MechanicWorkLogLaunch extends WorkLogLaunch {
  const MechanicWorkLogLaunch({required this.vehicle});

  final WorkLogVehicle vehicle;
}

/// Unica dipendenza esterna della feature. L'app compone il repository con il
/// proprio client autenticato; BLoC e use case restano interni a WorkLog.
class WorkLogDependencies {
  const WorkLogDependencies({required this.repository});

  final WorkLogRepository repository;
}
