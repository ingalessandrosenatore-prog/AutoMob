import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/haptic_service.dart';
import '../../theme/am_theme_colors.dart';

/// ChoiceChip personalizzato AutoMob.
/// Segue lo stile della foto: bordo colorato quando selezionato, sfondo scuro,
/// icona di check opzionale.
class AmChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final int id;

  const AmChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = const Color(0xFFE85A1A), required this.id,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return GestureDetector(
      onTap: () {
        AmHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : colors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              HugeIcon(
                icon: HugeIcons.strokeRoundedValidation,
                size: 14,
                color: colors.textPrimary,
                strokeWidth: 2.2,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
