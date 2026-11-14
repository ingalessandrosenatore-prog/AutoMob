import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_draft.dart';
import '../domain/work_log_parts_catalog.dart';
import 'work_log_part_category_filter.dart';
import 'work_log_part_icons.dart';

/// Griglia ricambi originale AutoMob, controllata dal Cubit condiviso.
class WorkLogPartsPicker extends StatelessWidget {
  const WorkLogPartsPicker({
    required this.selectedParts,
    required this.query,
    required this.selectedCategory,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onPartToggled,
    this.topPadding = 0,
    super.key,
  });

  final List<WorkLogPartDraft> selectedParts;
  final String query;
  final WorkLogPartCategory? selectedCategory;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<WorkLogPartCategory> onCategoryChanged;
  final ValueChanged<int> onPartToggled;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final selectedIds = selectedParts.map((part) => part.partId).toSet();
    final normalized = query.trim().toLowerCase();
    final parts = kWorkLogPartsCatalog.entries
        .where((entry) {
          if (normalized.isNotEmpty) {
            return entry.value.name.toLowerCase().contains(normalized);
          }
          return selectedCategory == null ||
              entry.value.category == selectedCategory;
        })
        .toList(growable: false);

    return Stack(
      children: [
        Positioned.fill(
          child: GridView.builder(
            key: const Key('work-log-parts-grid'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, topPadding + 110, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.15,
            ),
            itemCount: parts.length,
            itemBuilder: (_, index) {
              final part = parts[index];
              return _PartTile(
                key: ValueKey('work-log-part-${part.key}'),
                label: part.value.name,
                icon: workLogPartIcon(part.key),
                svgAsset: workLogPartSvgAsset(part.key),
                selected: selectedIds.contains(part.key),
                onTap: () => onPartToggled(part.key),
              );
            },
          ),
        ),
        Positioned(
          top: topPadding + 6,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('work-log-parts-search'),
                onChanged: onQueryChanged,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceRaised,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 46,
                    minHeight: 42,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: colors.textPrimary.withValues(alpha: 0.85),
                      size: 20,
                      strokeWidth: 2,
                    ),
                  ),
                  hintText: 'Nome del ricambio',
                  hintStyle: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: colors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(color: colors.accent, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              WorkLogPartCategoryFilter(
                selectedCategory: selectedCategory,
                onChanged: onCategoryChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.svgAsset,
    super.key,
  });

  final String label;
  final List<List<dynamic>> icon;
  final String? svgAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? colors.accent.withValues(alpha: .16)
                : colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.accent
                  : colors.border.withValues(alpha: 0.55),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  padding: EdgeInsets.all(svgAsset != null ? 4 : 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.accent.withValues(alpha: 0.2)
                        : colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      scale: selected ? 1.08 : 1,
                      child: svgAsset != null
                          ? SvgPicture.asset(
                              svgAsset!,
                              package: 'automob_work_log',
                              fit: BoxFit.contain,
                            )
                          : HugeIcon(
                              icon: icon,
                              color: selected
                                  ? colors.accent
                                  : colors.textPrimary.withValues(alpha: 0.85),
                              size: 26,
                              strokeWidth: 1.9,
                            ),
                    ),
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
