import 'package:flutter/material.dart';

import '../../services/haptic_service.dart';

/// Il pulsante principale (Main FAB) dell'applicazione.
/// Design a "pillola" con colore pieno, icona, testo e ombra luminescente (glow).
class AmMainFab extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final double width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;

  const AmMainFab({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    required this.width,
    required this.height,
    this.fontSize = 18,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      // padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            // Il glow basato sul colore in ingresso
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        // Aggiungiamo Material per l'effetto tocco
        color: color,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            AmHaptics.action();
            onPressed();
          },
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: fontWeight,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
