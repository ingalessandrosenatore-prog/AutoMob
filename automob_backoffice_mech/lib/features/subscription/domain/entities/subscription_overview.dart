import 'package:equatable/equatable.dart';

enum SubscriptionStatus { active, expiring, expired, inactive }

enum SubscriptionBillingCycle {
  monthly,
  yearly;

  static SubscriptionBillingCycle? fromCode(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'monthly' => SubscriptionBillingCycle.monthly,
        'yearly' => SubscriptionBillingCycle.yearly,
        _ => null,
      };
}

enum SubscriptionPlan {
  none,
  base,
  premium,
  elite;

  static SubscriptionPlan fromCode(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'base' => SubscriptionPlan.base,
        'premium' => SubscriptionPlan.premium,
        'elite' => SubscriptionPlan.elite,
        _ => SubscriptionPlan.none,
      };

  String get displayName => switch (this) {
    SubscriptionPlan.none => 'Nessun piano',
    SubscriptionPlan.base => 'AutoMob Base',
    SubscriptionPlan.premium => 'AutoMob Premium',
    SubscriptionPlan.elite => 'AutoMob Elite',
  };

  int? get vehicleLimit => switch (this) {
    SubscriptionPlan.none => 0,
    SubscriptionPlan.base => 30,
    SubscriptionPlan.premium => 100,
    SubscriptionPlan.elite => null,
  };
}

final class SubscriptionOverview extends Equatable {
  const SubscriptionOverview({
    required this.workshopName,
    required this.mechanicCode,
    required this.plan,
    this.billingCycle,
    required this.status,
    required this.expiresAt,
    required this.daysRemaining,
    required this.linkedVehicles,
  });

  final String workshopName;
  final String mechanicCode;
  final SubscriptionPlan plan;
  final SubscriptionBillingCycle? billingCycle;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final int daysRemaining;
  final int linkedVehicles;

  bool get hasPlan => plan != SubscriptionPlan.none;

  String get planName => plan.displayName;

  int? get vehicleLimit => plan.vehicleLimit;

  bool get hasUnlimitedVehicles => vehicleLimit == null;

  double get vehicleUsage => vehicleLimit == null || vehicleLimit == 0
      ? 0
      : (linkedVehicles / vehicleLimit!).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [
    workshopName,
    mechanicCode,
    plan,
    billingCycle,
    status,
    expiresAt,
    daysRemaining,
    linkedVehicles,
  ];
}
