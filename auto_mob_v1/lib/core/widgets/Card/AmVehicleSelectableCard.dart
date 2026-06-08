import 'package:flutter/material.dart';

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
    const Color blueColor = Color(0xFF4A90E2);
    const Color darkContainerColor = Color(0xFF1C1C1E);
    const Color labelColor = Color(0xFF636366);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? blueColor.withOpacity(0.05) : darkContainerColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? blueColor : Colors.white.withOpacity(0.05),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: blueColor.withOpacity(0.2),
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
                Icon(
                  Icons.directions_car_filled_outlined,
                  size: 16,
                  color: isSelected ? blueColor : labelColor,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              plate.toUpperCase(),
              style: const TextStyle(
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
