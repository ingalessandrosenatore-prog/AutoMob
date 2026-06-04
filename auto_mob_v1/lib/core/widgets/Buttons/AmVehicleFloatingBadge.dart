import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Un badge flottante che indica il veicolo selezionato.
/// Estetica: Pillola blu con icona auto e freccia per dropdown.
class AmVehicleFloatingBadge extends StatelessWidget {
  final String brand;
  final String model;
  final VoidCallback onTap;

  const AmVehicleFloatingBadge({
    super.key,
    required this.brand,
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color blueColor = Color(0xFF4A90E2);

    return GestureDetector(
      onTap: onTap,
      child: OCLiquidGlassGroup(
        settings: OCLiquidGlassSettings(
            refractStrength: -0.110, // Stronger refraction
            blurRadiusPx: 2, // Add frosted glass blur
            specStrength: 0,
            specWidth:0.0,


        ),
        child: OCLiquidGlass(
          color: blueColor.withOpacity(0.5),
          borderRadius: 100,

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: blueColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$brand $model",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
