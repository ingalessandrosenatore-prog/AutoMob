import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';

const _workLogCardSmoothing = 0.8;

SmoothRectangleBorder _workLogShape({double radius = 22}) =>
    SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: _workLogCardSmoothing,
      ),
    );

/// Card per la visualizzazione di un intervento nello storico.
/// Estetica: Dark, con badge "Officina" opzionale.
class WorkLogItemCard extends StatelessWidget {
  final String title;
  final String date;
  final String km;
  final String description;
  final bool hasWorkshop;
  final VoidCallback? onTap;

  const WorkLogItemCard({
    super.key,
    required this.title,
    required this.date,
    required this.km,
    required this.description,
    this.hasWorkshop = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color orangeColor = Color(0xFFE85A1A);
    final colors = AmThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surface,
        shape: _workLogShape().copyWith(side: BorderSide(color: colors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: _workLogShape(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (hasWorkshop) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: orangeColor.withValues(alpha: 0.15),
                          shape: _workLogShape(radius: 8),
                        ),
                        child: const Text(
                          'Officina',
                          style: TextStyle(
                            color: orangeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$date · $km',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: colors.border, height: 1),
                const SizedBox(height: 12),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
