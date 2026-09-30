import 'package:automob_backoffice_mech/features/subscription/data/models/subscription_overview_model.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/entities/subscription_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte la risposta RPC completa', () {
    final model = SubscriptionOverviewModel.fromJson({
      'workshop_name': 'Officina Test',
      'mechanic_code': '482913',
      'plan_code': 'premium',
      'plan_name': 'AutoMob Premium',
      'billing_cycle': 'yearly',
      'status': 'expiring',
      'expires_at': '2027-01-15T12:00:00+00:00',
      'days_remaining': 12,
      'linked_vehicles': 4,
      'vehicle_limit': 40,
    });

    expect(model.mechanicCode, '482913');
    expect(model.status, SubscriptionStatus.expiring);
    expect(model.plan, SubscriptionPlan.premium);
    expect(model.billingCycle, SubscriptionBillingCycle.yearly);
    expect(model.expiresAt, DateTime.parse('2027-01-15T12:00:00+00:00'));
    expect(model.linkedVehicles, 4);
    expect(model.toEntity().vehicleLimit, 100);
  });

  test('gestisce un meccanico senza abbonamento', () {
    final model = SubscriptionOverviewModel.fromJson({
      'workshop_name': 'Officina Test',
      'mechanic_code': '482913',
      'plan_code': 'none',
      'plan_name': 'Nessun piano',
      'billing_cycle': null,
      'status': 'inactive',
      'expires_at': null,
      'days_remaining': 0,
      'linked_vehicles': 0,
      'vehicle_limit': 0,
    });

    expect(model.status, SubscriptionStatus.inactive);
    expect(model.plan, SubscriptionPlan.none);
    expect(model.billingCycle, isNull);
    expect(model.expiresAt, isNull);
  });

  test('tratta un codice piano sconosciuto come nessun piano', () {
    final model = SubscriptionOverviewModel.fromJson({
      'workshop_name': 'Officina Test',
      'mechanic_code': '482913',
      'plan_code': 'legacy',
      'plan_name': 'Legacy',
      'billing_cycle': 'monthly',
      'status': 'active',
      'expires_at': null,
      'days_remaining': 0,
      'linked_vehicles': 0,
      'vehicle_limit': 0,
    });

    expect(model.plan, SubscriptionPlan.none);
    expect(model.billingCycle, isNull);
    expect(model.status, SubscriptionStatus.inactive);
  });
}
