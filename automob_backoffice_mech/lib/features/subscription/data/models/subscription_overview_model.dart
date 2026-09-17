import '../../domain/entities/subscription_overview.dart';

final class SubscriptionOverviewModel {
  const SubscriptionOverviewModel({
    required this.workshopName,
    required this.mechanicCode,
    required this.plan,
    this.billingCycle,
    required this.status,
    required this.expiresAt,
    required this.daysRemaining,
    required this.linkedVehicles,
  });

  factory SubscriptionOverviewModel.fromJson(Map<String, dynamic> json) {
    final expiryValue = json['expires_at']?.toString();
    final plan = SubscriptionPlan.fromCode(json['plan_code']);
    return SubscriptionOverviewModel(
      workshopName: _requiredText(json, 'workshop_name'),
      mechanicCode: _requiredText(json, 'mechanic_code'),
      plan: plan,
      billingCycle: plan == SubscriptionPlan.none
          ? null
          : SubscriptionBillingCycle.fromCode(json['billing_cycle']),
      status: plan == SubscriptionPlan.none
          ? SubscriptionStatus.inactive
          : switch (json['status']?.toString()) {
              'active' => SubscriptionStatus.active,
              'expiring' => SubscriptionStatus.expiring,
              'expired' => SubscriptionStatus.expired,
              _ => SubscriptionStatus.inactive,
            },
      expiresAt: expiryValue == null ? null : DateTime.parse(expiryValue),
      daysRemaining: _requiredInt(json, 'days_remaining'),
      linkedVehicles: _requiredInt(json, 'linked_vehicles'),
    );
  }

  final String workshopName;
  final String mechanicCode;
  final SubscriptionPlan plan;
  final SubscriptionBillingCycle? billingCycle;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final int daysRemaining;
  final int linkedVehicles;

  SubscriptionOverview toEntity() => SubscriptionOverview(
    workshopName: workshopName,
    mechanicCode: mechanicCode,
    plan: plan,
    billingCycle: billingCycle,
    status: status,
    expiresAt: expiresAt,
    daysRemaining: daysRemaining,
    linkedVehicles: linkedVehicles,
  );
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim();
  if (value == null || value.isEmpty) {
    throw FormatException('Campo $key assente');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}
