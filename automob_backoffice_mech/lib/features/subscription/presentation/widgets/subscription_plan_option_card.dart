import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/entities/subscription_overview.dart';
import '../models/subscription_plan_option.dart';

class SubscriptionPlanOptionCard extends StatelessWidget {
  const SubscriptionPlanOptionCard({
    super.key,
    required this.plan,
    required this.cycle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final SubscriptionPlanOption plan;
  final SubscriptionBillingCycle cycle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final recommended = plan.plan == SubscriptionPlan.premium;
    final price = cycle == SubscriptionBillingCycle.monthly
        ? plan.monthlyPrice
        : plan.discountedMonthlyPrice;
    return Material(
      key: ValueKey('subscription_plan_${plan.name.toLowerCase()}'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: recommended
                  ? colors.accent.withValues(alpha: 0.55)
                  : colors.textPrimary.withValues(alpha: 0.07),
              width: recommended ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanIcon(plan: plan.plan, highlighted: recommended),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _RecommendedBadge(color: colors.accent),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          plan.subtitle,
                          style: TextStyle(
                            color: colors.textSecondary,
                            height: 1.3,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '/mese',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (cycle == SubscriptionBillingCycle.yearly) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-10%',
                                style: TextStyle(
                                  color: colors.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final feature in plan.features) ...[
                _FeatureRow(label: feature),
                const SizedBox(height: 9),
              ],
              const SizedBox(height: 9),
              Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: recommended ? colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: recommended
                        ? colors.accent
                        : colors.textPrimary.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: recommended ? Colors.white : colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.plan, required this.highlighted});

  final SubscriptionPlan plan;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final icon = switch (plan) {
      SubscriptionPlan.none => HugeIcons.strokeRoundedCancelCircle,
      SubscriptionPlan.base => HugeIcons.strokeRoundedCar01,
      SubscriptionPlan.premium => HugeIcons.strokeRoundedNotification01,
      SubscriptionPlan.elite => HugeIcons.strokeRoundedCrown,
    };
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: (highlighted ? colors.accent : colors.textPrimary).withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: highlighted ? colors.accent : colors.textPrimary,
          size: 23,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedTick02,
              color: colors.accent,
              size: 13,
              strokeWidth: 2.4,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'CONSIGLIATO',
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    ),
  );
}
