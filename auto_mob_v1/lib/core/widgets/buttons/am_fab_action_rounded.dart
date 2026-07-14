import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/haptic_service.dart';

/// Un widget che rappresenta un'azione singola per un menu FAB espandibile.
/// Segue lo stile: sfondo scuro trasparente, bordo colorato e effetto glow.
class AmFabAction extends StatelessWidget {
  final Color color;
  final List<List> icon;
  final String label;
  final VoidCallback onPressed;

  const AmFabAction({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Label del comando (Pillola scura)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Pulsante Circolare con bordo e Glow
          GestureDetector(
            onTap: () {
              AmHaptics.tap();
              onPressed();
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:  Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: HugeIcon(
                icon: icon,
                color: color,
                size: 25,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
