import '../../domain/entities/subscription_overview.dart';

final class SubscriptionPlanOption {
  const SubscriptionPlanOption({
    required this.plan,
    required this.name,
    required this.subtitle,
    required this.monthlyPrice,
    required this.discountedMonthlyPrice,
    required this.features,
  });

  final SubscriptionPlan plan;
  final String name;
  final String subtitle;
  final String monthlyPrice;
  final String discountedMonthlyPrice;
  final List<String> features;

  static const all = [
    SubscriptionPlanOption(
      plan: SubscriptionPlan.base,
      name: 'Base',
      subtitle: 'Per iniziare con tutto l’essenziale',
      monthlyPrice: '€25,89',
      discountedMonthlyPrice: '€23,30',
      features: ['30 veicoli', 'Gestione lavori e scadenze'],
    ),
    SubscriptionPlanOption(
      plan: SubscriptionPlan.premium,
      name: 'Premium',
      subtitle: 'Per officine che vogliono crescere',
      monthlyPrice: '€41,99',
      discountedMonthlyPrice: '€37,79',
      features: [
        'Tutto quello del Base',
        'Fino a 100 veicoli',
        'Notifiche automatiche ai clienti',
      ],
    ),
    SubscriptionPlanOption(
      plan: SubscriptionPlan.elite,
      name: 'Elite',
      subtitle: 'La libertà di lavorare senza limiti',
      monthlyPrice: '€110,99',
      discountedMonthlyPrice: '€99,89',
      features: [
        'Tutto quello del Premium',
        'Veicoli illimitati',
        'Assistenza prioritaria',
      ],
    ),
  ];
}
