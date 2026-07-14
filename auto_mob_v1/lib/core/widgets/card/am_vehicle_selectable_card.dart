import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';

/// Card veicolo selezionabile orizzontalmente.
/// Estetica: Dark, con bordo blu animato quando selezionata.
class AmVehicleSelectableCard extends StatelessWidget {
  final String brand;
  final String model;
  final String plate;
  final String fuelType; // es: BEN, IBR
  final bool isSelected;
  final VoidCallback onTap;

  const AmVehicleSelectableCard({
    super.key,
    required this.brand,
    required this.model,
    required this.plate,
    required this.fuelType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final blueColor = colors.info;
    final labelColor = colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? blueColor.withValues(alpha: 0.08) : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? blueColor : colors.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: blueColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCar03,
                  size: 16,
                  color: isSelected ? blueColor : labelColor,
                  strokeWidth: 2.2,
                ),
                const SizedBox(width: 8),
                Text(
                  fuelType.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? blueColor : labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              plate.toUpperCase(),
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
