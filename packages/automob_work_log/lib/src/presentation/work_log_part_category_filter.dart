import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_parts_catalog.dart';
import 'work_log_part_icons.dart';

class WorkLogPartCategoryFilter extends StatelessWidget {
  const WorkLogPartCategoryFilter({
    required this.selectedCategory,
    required this.onChanged,
    super.key,
  });

  final WorkLogPartCategory? selectedCategory;
  final ValueChanged<WorkLogPartCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return SingleChildScrollView(
      key: const Key('work-log-part-categories'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var index = 0;
            index < WorkLogPartCategory.values.length;
            index++
          ) ...[
            if (index > 0) const SizedBox(width: 7),
            _CategoryChip(
              category: WorkLogPartCategory.values[index],
              selected: selectedCategory == WorkLogPartCategory.values[index],
              colors: colors,
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.colors,
    required this.onChanged,
  });

  final WorkLogPartCategory category;
  final bool selected;
  final AmThemeColors colors;
  final ValueChanged<WorkLogPartCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? colors.onMedia
        : colors.textPrimary.withValues(alpha: 0.9);
    return ChoiceChip(
      key: ValueKey('work-log-part-category-${category.wireValue}'),
      selected: selected,
      showCheckmark: false,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      avatar: HugeIcon(
        icon: workLogPartCategoryIcon(category),
        color: foreground,
        size: 16,
        strokeWidth: 1.9,
      ),
      label: Text(category.label),
      labelStyle: TextStyle(
        color: foreground,
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      labelPadding: const EdgeInsets.only(left: 4, right: 4),
      backgroundColor: colors.surfaceRaised,
      selectedColor: colors.accent.withValues(alpha: 0.32),
      side: BorderSide(
        color: selected ? colors.accent : colors.border.withValues(alpha: 0.6),
        width: selected ? 1.2 : 1,
      ),
      shape: const StadiumBorder(),
      onSelected: (_) => onChanged(category),
    );
  }
}
