import 'package:flutter/material.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:hugeicons/hugeicons.dart';

class MaintenanceSectionCard extends StatelessWidget {
  final Object? icon;
  final String title;
  final List<Widget> children;

  /// Colore dell'icona. Default bianco: invariato per gli usi gia'
  /// esistenti in app (wizard a pop-up).
  final Color? iconColor;

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
    this.iconColor,
    this.uppercaseTitle = false,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      // height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceHighlight, colors.surfaceRaised],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [

              iconWidget ??
                  (icon is List
                      ? HugeIcon(
                          icon: icon as List<List>,
                          size: 18,
                          color: iconColor,
                          strokeWidth: 2.2,
                        )
                      : Icon(icon as IconData, size: 18, color: iconColor)),

              const SizedBox(width: 10),
              Text(
                uppercaseTitle ? title.toUpperCase() : title,
                style: TextStyle(
                  color: colors.textPrimary,
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
