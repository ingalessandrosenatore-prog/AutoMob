import '../entities/workshop_overview_catalog.dart';

abstract interface class WorkshopOverviewRepository {
  Future<WorkshopOverviewCatalog> getOverview(DateTime referenceDate);
}
