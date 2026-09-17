import '../../domain/entities/subscription_overview.dart';

abstract final class SubscriptionWhatsAppLink {
  static const _phoneNumber = '393476505572';

  static Uri forPlan({
    required String planName,
    required SubscriptionBillingCycle cycle,
  }) {
    final billingLabel = switch (cycle) {
      SubscriptionBillingCycle.monthly => 'mensile',
      SubscriptionBillingCycle.yearly => 'annuale',
    };
    return _build(
      'Ciao, vorrei attivare il piano $planName con fatturazione '
      '$billingLabel e ricevere maggiori informazioni.',
    );
  }

  static Uri forSupport() => _build(
    'Ciao, vorrei ricevere maggiori informazioni sugli abbonamenti AutoMob.',
  );

  static Uri _build(String message) =>
      Uri.https('wa.me', '/$_phoneNumber', {'text': message});
}
