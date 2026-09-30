import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/subscription_overview.dart';
import '../helpers/subscription_whatsapp_link.dart';
import '../models/subscription_plan_option.dart';
import '../widgets/subscription_billing_selector.dart';
import '../widgets/subscription_cards.dart';
import '../widgets/subscription_plan_option_card.dart';

typedef SubscriptionUriLauncher = Future<bool> Function(Uri uri);

class SubscriptionPlanPage extends StatefulWidget {
  const SubscriptionPlanPage({
    super.key,
    this.currentOverview,
    this.uriLauncher = launchUrl,
  });

  final SubscriptionOverview? currentOverview;
  final SubscriptionUriLauncher uriLauncher;

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  late final ValueNotifier<SubscriptionBillingCycle> _billingCycle;

  @override
  void initState() {
    super.initState();
    _billingCycle = ValueNotifier(
      widget.currentOverview?.billingCycle ?? SubscriptionBillingCycle.monthly,
    );
  }

  @override
  void dispose() {
    _billingCycle.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(Uri uri) async {
    try {
      if (await widget.uriLauncher(uri)) return;
    } on Exception {
      // The same feedback covers unavailable WhatsApp and launcher failures.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Non è stato possibile aprire WhatsApp.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final currentOverview = widget.currentOverview;
    final hasCurrentPlan = currentOverview?.hasPlan ?? false;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: Navigator.of(context).maybePop,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: colors.textPrimary,
            size: 24,
            strokeWidth: 2.2,
          ),
        ),
        title: Text(
          'Abbonamento',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ValueListenableBuilder<SubscriptionBillingCycle>(
        valueListenable: _billingCycle,
        builder: (context, cycle, _) => ListView(
          key: const ValueKey('subscription_plan_list'),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
          children: [
            if (hasCurrentPlan) ...[
              SubscriptionPlanCard(overview: currentOverview!),
              const SizedBox(height: 28),
              Text(
                'Altri piani',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confronta le alternative e aggiorna il tuo abbonamento.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ] else ...[
              Text(
                'Scegli il piano giusto per la tua officina',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Inizia con una prova gratuita e disdici quando vuoi. Nessun vincolo, solo gli strumenti che ti servono.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SubscriptionBillingSelector(
              selected: cycle,
              onChanged: (value) => _billingCycle.value = value,
            ),
            const SizedBox(height: 18),
            for (final plan in SubscriptionPlanOption.all.where(
              (plan) => !hasCurrentPlan || plan.plan != currentOverview!.plan,
            )) ...[
              SubscriptionPlanOptionCard(
                plan: plan,
                cycle: cycle,
                buttonLabel: hasCurrentPlan
                    ? 'AGGIORNA'
                    : 'INIZIA LA PROVA GRATUITA',
                onPressed: () => _openWhatsApp(
                  SubscriptionWhatsAppLink.forPlan(
                    planName: plan.name,
                    cycle: cycle,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AmMainFab(
        key: const ValueKey('subscription_contact_button'),
        label: 'CONTATTACI',
        icon: HugeIcons.strokeRoundedCustomerSupport,
        color: colors.accent,
        width: 280,
        height: 54,
        fontSize: 14,
        onPressed: () => _openWhatsApp(SubscriptionWhatsAppLink.forSupport()),
      ),
    );
  }
}
