import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/subscription_overview.dart';

class SubscriptionBillingSelector extends StatelessWidget {
  const SubscriptionBillingSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final SubscriptionBillingCycle selected;
  final ValueChanged<SubscriptionBillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      key: const ValueKey('subscription_billing_selector'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _BillingChoice(
            label: 'Mensile',
            selected: selected == SubscriptionBillingCycle.monthly,
            onTap: () => onChanged(SubscriptionBillingCycle.monthly),
          ),
          _BillingChoice(
            label: 'Annuale',
            badge: '10%',
            selected: selected == SubscriptionBillingCycle.yearly,
            onTap: () => onChanged(SubscriptionBillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _BillingChoice extends StatelessWidget {
  const _BillingChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? colors.textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? colors.background : colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
