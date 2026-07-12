import 'package:flutter/material.dart';

/// Banner informativo/di avviso condiviso tra gli step del wizard di
/// registrazione: sfondo tenue colorato, icona in un badge quadrato
/// centrato verticalmente rispetto al testo (anche su piu' righe), testo
/// a fianco. Stessa estetica ovunque venga usato: cambiano solo colore,
/// icona e testo passati dal chiamante.
class StepInfoBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const StepInfoBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
                fontWeight: FontWeight.normal,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
