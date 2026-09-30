enum WorkshopPeriod { day, month, year }

class WorkshopOverview {
  const WorkshopOverview({
    required this.period,
    required this.revenueCents,
    required this.completedJobs,
    required this.availableJobs,
  });

  final WorkshopPeriod period;
  final int revenueCents;
  final int completedJobs;
  final int availableJobs;
}
