import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';

/// Pulsante Outlined personalizzato per AutoMob.
/// Utilizzato principalmente per azioni secondarie come "Indietro".
/// Include un effetto glow sul testo basato sul colore principale.
class AmOutlinedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const AmOutlinedButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        AmHaptics.tap();
        onPressed();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        // Rimuoviamo il feedback splash standard per mantenere lo stile pulito
        foregroundColor: color,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          shadows: [
            // Effetto Glow sulla scritta
            Shadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8.0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }
}
