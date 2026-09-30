import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcola i massimi dal fatturato annuo su 300 giorni e 12 mesi', () {
    const catalog = WorkshopOverviewCatalog(
      day: WorkshopOverview(
        period: WorkshopPeriod.day,
        revenueCents: 150000,
        completedJobs: 4,
        availableJobs: 1,
      ),
      month: WorkshopOverview(
        period: WorkshopPeriod.month,
        revenueCents: 1500000,
        completedJobs: 40,
        availableJobs: 1,
      ),
      year: WorkshopOverview(
        period: WorkshopPeriod.year,
        revenueCents: 30000000,
        completedJobs: 400,
        availableJobs: 1,
      ),
    );

    expect(catalog.revenueMaximumFor(WorkshopPeriod.day), 100000);
    expect(catalog.revenueMaximumFor(WorkshopPeriod.month), 2500000);
    expect(catalog.revenueMaximumFor(WorkshopPeriod.year), 30000000);
  });
}
