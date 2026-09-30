import '../entities/workshop_overview_catalog.dart';
import '../repositories/workshop_overview_repository.dart';

class GetWorkshopOverview {
  const GetWorkshopOverview(this.repository);
  final WorkshopOverviewRepository repository;

  Future<WorkshopOverviewCatalog> call(DateTime referenceDate) =>
      repository.getOverview(referenceDate);
}
