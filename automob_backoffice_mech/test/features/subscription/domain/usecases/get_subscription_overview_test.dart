import 'package:automob_backoffice_mech/features/subscription/domain/entities/subscription_overview.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/usecases/get_subscription_overview.dart';
import 'package:automob_backoffice_mech/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  test('restituisce lo snapshot fornito dal repository', () async {
    final overview = SubscriptionOverview(
      workshopName: 'Officina Test',
      mechanicCode: '123456',
      plan: SubscriptionPlan.premium,
      status: SubscriptionStatus.active,
      expiresAt: DateTime(2027),
      daysRemaining: 30,
      linkedVehicles: 4,
    );
    final useCase = GetSubscriptionOverview(_SubscriptionRepository(overview));

    final result = await useCase();

    expect(result, Right(overview));
  });

  test('deriva il limite veicoli dal piano attivo', () {
    const base = SubscriptionOverview(
      workshopName: 'Officina Test',
      mechanicCode: '123456',
      plan: SubscriptionPlan.base,
      status: SubscriptionStatus.active,
      expiresAt: null,
      daysRemaining: 30,
      linkedVehicles: 6,
    );
    const premium = SubscriptionOverview(
      workshopName: 'Officina Test',
      mechanicCode: '123456',
      plan: SubscriptionPlan.premium,
      status: SubscriptionStatus.active,
      expiresAt: null,
      daysRemaining: 30,
      linkedVehicles: 6,
    );
    const elite = SubscriptionOverview(
      workshopName: 'Officina Test',
      mechanicCode: '123456',
      plan: SubscriptionPlan.elite,
      status: SubscriptionStatus.active,
      expiresAt: null,
      daysRemaining: 30,
      linkedVehicles: 6,
    );

    expect(base.vehicleLimit, 30);
    expect(premium.vehicleLimit, 100);
    expect(elite.vehicleLimit, isNull);
    expect(elite.hasUnlimitedVehicles, isTrue);
  });

  test('calcola l utilizzo premium senza superare il cento per cento', () {
    const overview = SubscriptionOverview(
      workshopName: 'Officina Test',
      mechanicCode: '123456',
      plan: SubscriptionPlan.premium,
      status: SubscriptionStatus.active,
      expiresAt: null,
      daysRemaining: 30,
      linkedVehicles: 120,
    );

    expect(overview.vehicleUsage, 1);
  });
}

final class _SubscriptionRepository implements SubscriptionRepository {
  const _SubscriptionRepository(this.overview);

  final SubscriptionOverview overview;

  @override
  Future<Either<Failure, SubscriptionOverview>> getOverview() async =>
      Right(overview);
}
