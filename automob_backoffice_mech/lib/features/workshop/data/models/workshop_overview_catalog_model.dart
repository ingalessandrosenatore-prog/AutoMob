import '../../domain/entities/workshop_overview.dart';
import '../../domain/entities/workshop_overview_catalog.dart';

class WorkshopOverviewCatalogModel extends WorkshopOverviewCatalog {
  const WorkshopOverviewCatalogModel({
    required super.day,
    required super.month,
    required super.year,
  });

  factory WorkshopOverviewCatalogModel.fromJson(Map<String, dynamic> json) {
    final availableJobs = (json['available_jobs'] as num?)?.toInt() ?? 0;
    final rawPeriods = json['periods'];
    if (rawPeriods is! Map) {
      throw const FormatException('Periodi KPI mancanti.');
    }
    final periods = Map<String, dynamic>.from(rawPeriods);
    return WorkshopOverviewCatalogModel(
      day: _overview(periods, 'day', WorkshopPeriod.day, availableJobs),
      month: _overview(periods, 'month', WorkshopPeriod.month, availableJobs),
      year: _overview(periods, 'year', WorkshopPeriod.year, availableJobs),
    );
  }

  static WorkshopOverview _overview(
    Map<String, dynamic> periods,
    String key,
    WorkshopPeriod period,
    int availableJobs,
  ) {
    final raw = periods[key];
    if (raw is! Map) throw FormatException('Periodo KPI $key mancante.');
    final json = Map<String, dynamic>.from(raw);
    return WorkshopOverview(
      period: period,
      revenueCents: (json['revenue_cents'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      availableJobs: availableJobs,
    );
  }
}
