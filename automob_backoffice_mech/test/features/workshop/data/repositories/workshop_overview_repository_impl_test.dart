import 'package:automob_backoffice_mech/features/workshop/data/datasources/workshop_overview_remote_data_source.dart';
import 'package:automob_backoffice_mech/features/workshop/data/models/workshop_overview_catalog_model.dart';
import 'package:automob_backoffice_mech/features/workshop/data/repositories/workshop_overview_repository_impl.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'forwards the reference date and returns the datasource snapshot',
    () async {
      final source = _FakeOverviewSource();
      final repository = WorkshopOverviewRepositoryImpl(source);
      final date = DateTime(2026, 9, 23);

      final result = await repository.getOverview(date);

      expect(result, same(_FakeOverviewSource.result));
      expect(source.referenceDate, date);
    },
  );
}

class _FakeOverviewSource implements WorkshopOverviewRemoteDataSource {
  static const result = WorkshopOverviewCatalogModel(
    day: _overviewDay,
    month: _overviewMonth,
    year: _overviewYear,
  );

  DateTime? referenceDate;

  @override
  Future<WorkshopOverviewCatalogModel> getOverview(
    DateTime referenceDate,
  ) async {
    this.referenceDate = referenceDate;
    return result;
  }
}

const _overviewDay = WorkshopOverview(
  period: WorkshopPeriod.day,
  revenueCents: 0,
  completedJobs: 0,
  availableJobs: 0,
);
const _overviewMonth = WorkshopOverview(
  period: WorkshopPeriod.month,
  revenueCents: 0,
  completedJobs: 0,
  availableJobs: 0,
);
const _overviewYear = WorkshopOverview(
  period: WorkshopPeriod.year,
  revenueCents: 0,
  completedJobs: 0,
  availableJobs: 0,
);
