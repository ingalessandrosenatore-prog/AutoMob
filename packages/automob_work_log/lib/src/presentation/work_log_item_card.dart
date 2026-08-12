import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../domain/work_log_entry.dart';

const _orange = Color(0xFFE85A1A);
const _smoothing = 0.8;

SmoothRectangleBorder _shape({double radius = 30}) => SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius(
    cornerRadius: radius,
    cornerSmoothing: _smoothing,
  ),
);

/// La card originale AutoMob adattata all'entita condivisa.
class WorkLogItemCard extends StatelessWidget {
  const WorkLogItemCard({required this.entry, required this.onTap, super.key});

  final WorkLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final description = entry.notes?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.surfaceHighlight,
        shape: _shape().copyWith(side: BorderSide(color: colors.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: _shape(),
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
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: ShapeDecoration(
                          color: _orange.withValues(alpha: 0.15),
                          shape: _shape(radius: 8),
                        ),
                        child: const Text(
                          'Officina',
                          style: TextStyle(
                            color: _orange,
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
                  '${_formatDate(entry.serviceDate)} · ${_formatKm(entry.serviceKm)}',
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
                  description?.isNotEmpty == true
                      ? description!
                      : 'Nessuna nota',
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

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatKm(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} km';
