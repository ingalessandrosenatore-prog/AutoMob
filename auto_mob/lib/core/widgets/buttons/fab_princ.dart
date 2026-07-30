import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/haptic_service.dart';

const _mainFabSmoothing = 0.8;

SmoothRectangleBorder _mainFabShape(double height) => SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius(
    cornerRadius: height / 2,
    cornerSmoothing: _mainFabSmoothing,
  ),
);

/// Il pulsante principale (Main FAB) dell'applicazione.
/// Design a "pillola" con colore pieno, icona, testo e ombra luminescente (glow).
class AmMainFab extends StatelessWidget {
  final String label;
  final Color color;
  final List<List>? icon;
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
      decoration: ShapeDecoration(
        color: color,
        shape: _mainFabShape(height),
        shadows: [
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
        shape: _mainFabShape(height),
        child: InkWell(
          customBorder: _mainFabShape(height),
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
                      HugeIcon(
                        icon: icon!,
                        color: Colors.white,
                        size: 20,
                        strokeWidth: 2.2,
                      ),
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
