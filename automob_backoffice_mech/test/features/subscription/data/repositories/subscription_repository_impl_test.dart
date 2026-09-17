import 'package:automob_backoffice_mech/features/subscription/data/datasources/subscription_data_source.dart';
import 'package:automob_backoffice_mech/features/subscription/data/models/subscription_overview_model.dart';
import 'package:automob_backoffice_mech/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/entities/subscription_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte lo snapshot del datasource nell entita di dominio', () async {
    final repository = SubscriptionRepositoryImpl(_SubscriptionDataSource());

    final result = await repository.getOverview();

    expect(
      result.getOrElse((_) => throw StateError('Risultato inatteso')),
      isA<SubscriptionOverview>()
          .having((value) => value.mechanicCode, 'mechanicCode', '123456')
          .having((value) => value.linkedVehicles, 'linkedVehicles', 7),
    );
  });
}

final class _SubscriptionDataSource implements SubscriptionDataSource {
  @override
  Future<SubscriptionOverviewModel> getOverview() async =>
      SubscriptionOverviewModel(
        workshopName: 'Officina Test',
        mechanicCode: '123456',
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.active,
        expiresAt: DateTime(2027),
        daysRemaining: 30,
        linkedVehicles: 7,
      );
}
