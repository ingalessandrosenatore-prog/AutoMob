import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';

/// Pulsante Outlined personalizzato per AutoMob.
/// Utilizzato principalmente per azioni secondarie come "Indietro".
/// Include un effetto glow sul testo basato sul colore principale.
class AmOutlinedButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// Colore di riempimento dello sfondo. Null (default) = trasparente,
  /// comportamento invariato per gli usi gia' esistenti in app.
  final Color? fillColor;

  const AmOutlinedButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.fillColor,
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
        backgroundColor: fillColor,
        // Rimuoviamo il feedback splash standard per mantenere lo stile pulito
        foregroundColor: color,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,

            // Effetto Glow sulla scritta

        ),
      ),
    );
  }
}
