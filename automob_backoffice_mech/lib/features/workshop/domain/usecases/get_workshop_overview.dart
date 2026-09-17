import '../entities/workshop_overview.dart';
import '../repositories/workshop_overview_repository.dart';

class GetWorkshopOverview {
  const GetWorkshopOverview(this.repository);
  final WorkshopOverviewRepository repository;

  WorkshopOverview call(WorkshopPeriod period) =>
      repository.getOverview(period);
}
