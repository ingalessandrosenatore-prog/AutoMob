import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/workshop_catalog.dart';
import '../repositories/workshop_repository.dart';

final class GetWorkshopCatalog {
  const GetWorkshopCatalog(this.repository);

  final WorkshopRepository repository;

  Future<Either<Failure, WorkshopCatalog>> call() async {
    final result = await repository.getCatalog();
    return result.map(_enrichCatalog);
  }

  WorkshopCatalog _enrichCatalog(WorkshopCatalog catalog) {
    final vehicles = catalog.vehicles.map(_calculateStatus).toList()
      ..sort(_compareVehicles);
    return WorkshopCatalog(mechanic: catalog.mechanic, vehicles: vehicles);
  }

  WorkshopVehicle _calculateStatus(WorkshopVehicle vehicle) {
    final tagliandoDue = _isDue(
      currentKm: vehicle.kmCurrent,
      lastServiceKm: vehicle.lastTagliandoKm,
      intervalKm: vehicle.tagliandoIntervalKm,
    );
    final distributionDue = _isDue(
      currentKm: vehicle.kmCurrent,
      lastServiceKm: vehicle.lastDistributionKm,
      intervalKm: vehicle.distributionIntervalKm,
    );
    final mandatoryWorks = <WorkshopMandatoryWork>[
      if (tagliandoDue)
        WorkshopMandatoryWork(
          type: WorkshopMandatoryWorkType.tagliando,
          title: 'Tagliando periodico',
          dueKm: vehicle.lastTagliandoKm! + vehicle.tagliandoIntervalKm,
          currentKm: vehicle.kmCurrent,
        ),
      if (distributionDue)
        WorkshopMandatoryWork(
          type: WorkshopMandatoryWorkType.distribution,
          title: 'Distribuzione',
          dueKm: vehicle.lastDistributionKm! + vehicle.distributionIntervalKm!,
          currentKm: vehicle.kmCurrent,
        ),
    ];
    final userProblems = vehicle.userProblems.isNotEmpty
        ? vehicle.userProblems
        : vehicle.warningLights.isNotEmpty
        ? [
            WorkshopUserProblem(
              id: 'lights-${vehicle.id}',
              description: '',
              warningLights: vehicle.warningLights,
            ),
          ]
        : const <WorkshopUserProblem>[];

    return vehicle.copyWith(
      mandatoryWorks: mandatoryWorks,
      userProblems: userProblems,
      requiresMaintenance: mandatoryWorks.isNotEmpty || userProblems.isNotEmpty,
    );
  }

  bool _isDue({
    required int currentKm,
    required int? lastServiceKm,
    required int? intervalKm,
  }) =>
      lastServiceKm != null &&
      intervalKm != null &&
      intervalKm > 0 &&
      currentKm >= lastServiceKm + intervalKm;

  int _compareVehicles(WorkshopVehicle left, WorkshopVehicle right) {
    if (left.requiresMaintenance != right.requiresMaintenance) {
      return left.requiresMaintenance ? -1 : 1;
    }
    final nameComparison = left.displayName.toLowerCase().compareTo(
      right.displayName.toLowerCase(),
    );
    if (nameComparison != 0) return nameComparison;
    return left.plate.toLowerCase().compareTo(right.plate.toLowerCase());
  }
}
