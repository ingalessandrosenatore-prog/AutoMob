import 'workshop_overview.dart';

class WorkshopOverviewCatalog {
  const WorkshopOverviewCatalog({
    required this.day,
    required this.month,
    required this.year,
  });

  final WorkshopOverview day;
  final WorkshopOverview month;
  final WorkshopOverview year;

  WorkshopOverview forPeriod(WorkshopPeriod period) => switch (period) {
    WorkshopPeriod.day => day,
    WorkshopPeriod.month => month,
    WorkshopPeriod.year => year,
  };

  /// Confronta il dato reale del periodo con la media ricavata dal totale annuo.
  int revenueMaximumFor(WorkshopPeriod period) => switch (period) {
    WorkshopPeriod.day => (year.revenueCents / 300).round(),
    WorkshopPeriod.month => (year.revenueCents / 12).round(),
    WorkshopPeriod.year => year.revenueCents,
  };
}
