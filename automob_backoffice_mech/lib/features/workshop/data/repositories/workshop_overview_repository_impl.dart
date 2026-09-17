import '../../domain/entities/workshop_overview.dart';
import '../../domain/repositories/workshop_overview_repository.dart';
import '../datasources/workshop_overview_demo_data_source.dart';

class WorkshopOverviewRepositoryImpl implements WorkshopOverviewRepository {
  const WorkshopOverviewRepositoryImpl(this.dataSource);
  final WorkshopOverviewDemoDataSource dataSource;

  @override
  WorkshopOverview getOverview(WorkshopPeriod period) =>
      dataSource.getOverview(period);
}
