import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';

/// Formatta un intero in km con il punto delle migliaia (es. 40000 -> "40.000").
String fmtKm(int v) => v.toString().replaceAllMapped(
  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);

/// Chip selezionabile per scegliere rapidamente un intervallo in km.
/// Quando `selected` è true si colora di arancione; il tap è gestito da `onTap`.
class IntervalChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const IntervalChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AmHaptics.selection();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ) ?? TextStyle(color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
