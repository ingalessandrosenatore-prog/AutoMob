import '../../domain/entities/workshop_overview.dart';

/// Explicit demo fixtures; these values do not represent workshop accounts.
class WorkshopOverviewDemoDataSource {
  const WorkshopOverviewDemoDataSource();

  WorkshopOverview getOverview(WorkshopPeriod period) {
    final (revenue, jobs, growth, jobsGrowth) = switch (period) {
      WorkshopPeriod.day => (1250, 8, 12, 2),
      WorkshopPeriod.month => (24800, 146, 18, 21),
      WorkshopPeriod.year => (268500, 1640, 15, 184),
    };
    return WorkshopOverview(
      period: period,
      revenue: revenue,
      completedJobs: jobs,
      availableJobs: 3,
      potentialRevenue: 2800,
      revenueGrowth: growth,
      jobsGrowth: jobsGrowth,
    );
  }
}
