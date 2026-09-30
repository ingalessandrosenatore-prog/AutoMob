import 'package:automob_backoffice_mech/features/workshop/data/models/workshop_overview_catalog_model.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps all aggregate periods and the shared available-job count', () {
    final model = WorkshopOverviewCatalogModel.fromJson({
      'available_jobs': 4,
      'periods': {
        'day': {'completed_jobs': 2, 'revenue_cents': 12345},
        'month': {'completed_jobs': 8, 'revenue_cents': 67890},
        'year': {'completed_jobs': 30, 'revenue_cents': 456789},
      },
    });

    expect(model.day.revenueCents, 12345);
    expect(model.month.completedJobs, 8);
    expect(model.forPeriod(WorkshopPeriod.year).availableJobs, 4);
  });

  test('rejects a response without the period catalog', () {
    expect(
      () => WorkshopOverviewCatalogModel.fromJson({'available_jobs': 0}),
      throwsFormatException,
    );
  });
}
