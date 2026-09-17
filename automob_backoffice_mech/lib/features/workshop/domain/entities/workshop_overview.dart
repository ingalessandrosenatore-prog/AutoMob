enum WorkshopPeriod { day, month, year }

class WorkshopOverview {
  const WorkshopOverview({
    required this.period,
    required this.revenue,
    required this.completedJobs,
    required this.availableJobs,
    required this.potentialRevenue,
    required this.revenueGrowth,
    required this.jobsGrowth,
  });

  final WorkshopPeriod period;
  final int revenue;
  final int completedJobs;
  final int availableJobs;
  final int potentialRevenue;
  final int revenueGrowth;
  final int jobsGrowth;
}
