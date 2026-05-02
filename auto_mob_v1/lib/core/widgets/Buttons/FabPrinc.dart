import 'package:flutter/material.dart';

/// Il pulsante principale (Main FAB) dell'applicazione.
/// Design a "pillola" con colore pieno, icona, testo e ombra luminescente (glow).
class AmMainFab extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final double width;
  final double height;

  const AmMainFab({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    required this.width,
    required this.height,

  });

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: width,
      height: height,
       // padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              // Il glow basato sul colore in ingresso
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child:Material( // Aggiungiamo Material per l'effetto tocco
          color: color,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
    );
  }
  }