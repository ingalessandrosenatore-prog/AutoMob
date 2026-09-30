import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/entities/subscription_overview.dart';
import '../models/subscription_plan_option.dart';

Future<void> showSubscriptionTrialSheet(
  BuildContext context, {
  required SubscriptionPlanOption plan,
  required SubscriptionBillingCycle cycle,
  required bool isUpdate,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      SubscriptionTrialSheet(plan: plan, cycle: cycle, isUpdate: isUpdate),
);

class SubscriptionTrialSheet extends StatelessWidget {
  const SubscriptionTrialSheet({
    super.key,
    required this.plan,
    required this.cycle,
    required this.isUpdate,
  });

  final SubscriptionPlanOption plan;
  final SubscriptionBillingCycle cycle;
  final bool isUpdate;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final price = cycle == SubscriptionBillingCycle.monthly
        ? '${plan.monthlyPrice} al mese'
        : '${plan.discountedMonthlyPrice} al mese con fatturazione annuale';
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: colors.textPrimary.withValues(alpha: 0.10)),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                isUpdate ? 'Passa a ${plan.name}' : 'La tua prova ${plan.name}',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUpdate
                    ? 'Aggiorna il tuo abbonamento e passa a ${plan.name} a $price.'
                    : 'Prova tutte le funzionalità del piano. Poi scegli liberamente se continuare a $price.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              const _TrialStep(
                icon: HugeIcons.strokeRoundedRocket01,
                title: 'Nessun addebito oggi',
                description: 'Il piano si attiva subito per la tua officina.',
                first: true,
              ),
              const _TrialStep(
                icon: HugeIcons.strokeRoundedNotification01,
                title: 'Ti avvisiamo prima del rinnovo',
                description: 'Nessuna sorpresa: saprai sempre cosa succede.',
              ),
              const _TrialStep(
                icon: HugeIcons.strokeRoundedCancelCircle,
                title: 'Disdici quando vuoi',
                description: 'Se cambi idea puoi fermarti senza vincoli.',
                last: true,
              ),
              const SizedBox(height: 22),
              AmMainFab(
                key: const ValueKey('start_subscription_trial_button'),
                label: isUpdate ? 'AGGIORNA' : 'INIZIA LA PROVA GRATUITA',
                color: colors.accent,
                width: double.infinity,
                height: 54,
                fontSize: 13,
                onPressed: () {},
              ),
              const SizedBox(height: 10),
              Text(
                'Nessun vincolo. Puoi disdire quando vuoi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrialStep extends StatelessWidget {
  const _TrialStep({
    required this.icon,
    required this.title,
    required this.description,
    this.first = false,
    this.last = false,
  });

  final List<List> icon;
  final String title;
  final String description;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                if (!first)
                  Expanded(
                    child: Container(width: 2, color: colors.surfaceRaised),
                  )
                else
                  const Spacer(),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.11),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      color: colors.accent,
                      size: 18,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: colors.surfaceRaised),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
