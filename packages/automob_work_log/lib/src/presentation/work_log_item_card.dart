import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_entry.dart';
import 'work_log_card_entrance.dart';
import 'work_log_type_icon.dart';

const _orange = Color(0xFFE85A1A);
const _smoothing = 0.8;

SmoothRectangleBorder _shape({double radius = 35}) => SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius(
    cornerRadius: radius,
    cornerSmoothing: _smoothing,
  ),
);

/// La card originale AutoMob adattata all'entita condivisa.
class WorkLogItemCard extends StatelessWidget {
  const WorkLogItemCard({
    required this.entry,
    required this.onTap,
    this.entranceIndex = 0,
    super.key,
  });

  final WorkLogEntry entry;
  final VoidCallback onTap;
  final int entranceIndex;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final description = entry.notes?.trim();
    return WorkLogCardEntrance(
      index: entranceIndex,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          key: const Key('work-log-item-card-surface'),
          decoration: ShapeDecoration(
            gradient: colors.cardBorderGradient,
            shape: _shape(),
            shadows: colors.cardShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: _shape()),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.surface,
                  shape: _shape(),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: _shape(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: _shape(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            key: const Key('work-log-item-type-icon'),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.09),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: HugeIcon(
                              icon: workLogTypeIcon(entry.type),
                              color: colors.textSecondary,
                              size: 25,
                              strokeWidth: 1.8,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (entry.hasWorkshop) ...[
                                      const SizedBox(width: 8),
                                      const _WorkshopBadge(),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 5,
                                  children: [
                                    _Metadata(
                                      icon: Icons.calendar_today_outlined,
                                      text: _formatDate(entry.serviceDate),
                                      color: colors.textSecondary,
                                    ),
                                    _Metadata(
                                      icon: Icons.speed_outlined,
                                      text: _formatKm(entry.serviceKm),
                                      color: colors.textSecondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                _Metadata(
                                  icon: Icons.description_outlined,
                                  text: description?.isNotEmpty == true
                                      ? description!
                                      : 'Nessuna nota',
                                  color: colors.textSecondary,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          HugeIcon(
                            key: const Key('work-log-item-open-icon'),
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            color: colors.textSecondary,
                            size: 20,
                            strokeWidth: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkshopBadge extends StatelessWidget {
  const _WorkshopBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: ShapeDecoration(
      color: _orange.withValues(alpha: 0.15),
      shape: _shape(radius: 8),
    ),
    child: const Text(
      'Officina',
      style: TextStyle(
        color: _orange,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata({
    required this.icon,
    required this.text,
    required this.color,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color color;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 12.5, height: 1.25),
        ),
      ),
    ],
  );
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatKm(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} km';
