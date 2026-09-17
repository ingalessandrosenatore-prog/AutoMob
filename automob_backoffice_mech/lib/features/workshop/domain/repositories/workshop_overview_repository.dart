import '../entities/workshop_overview.dart';

abstract interface class WorkshopOverviewRepository {
  WorkshopOverview getOverview(WorkshopPeriod period);
}
