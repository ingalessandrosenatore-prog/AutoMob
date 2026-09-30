import '../../domain/entities/workshop_overview.dart';
import '../../domain/entities/workshop_overview_catalog.dart';

sealed class WorkshopOverviewState {
  const WorkshopOverviewState();
}

final class WorkshopOverviewLoading extends WorkshopOverviewState {
  const WorkshopOverviewLoading();
}

final class WorkshopOverviewReady extends WorkshopOverviewState {
  const WorkshopOverviewReady(this.catalog, {required this.period});

  final WorkshopOverviewCatalog catalog;
  final WorkshopPeriod period;

  WorkshopOverview get overview => catalog.forPeriod(period);
}

final class WorkshopOverviewFailure extends WorkshopOverviewState {
  const WorkshopOverviewFailure();
}
