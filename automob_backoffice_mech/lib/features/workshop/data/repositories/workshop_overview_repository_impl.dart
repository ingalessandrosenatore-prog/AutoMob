import '../../domain/entities/workshop_overview_catalog.dart';
import '../../domain/repositories/workshop_overview_repository.dart';
import '../datasources/workshop_overview_remote_data_source.dart';

class WorkshopOverviewRepositoryImpl implements WorkshopOverviewRepository {
  const WorkshopOverviewRepositoryImpl(this.dataSource);
  final WorkshopOverviewRemoteDataSource dataSource;

  @override
  Future<WorkshopOverviewCatalog> getOverview(DateTime referenceDate) =>
      dataSource.getOverview(referenceDate);
}
