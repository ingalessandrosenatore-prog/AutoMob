import 'package:flutter/material.dart';

class MaintenanceSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  /// Colore dell'icona. Default bianco: invariato per gli usi gia'
  /// esistenti in app (wizard a pop-up).
  final Color iconColor;

  /// Se true, il titolo viene mostrato in maiuscolo. Default false:
  /// invariato per gli usi gia' esistenti in app.
  final bool uppercaseTitle;

  /// Widget alternativo per l'icona (es. un SVG), al posto di [icon].
  /// Se presente ha la precedenza; [icon] resta comunque richiesto per
  /// compatibilita' con gli usi esistenti.
  final Widget? iconWidget;

  const MaintenanceSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor = Colors.white,
    this.uppercaseTitle = false,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      // height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              iconWidget ?? Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Text(
                uppercaseTitle ? title.toUpperCase() : title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
