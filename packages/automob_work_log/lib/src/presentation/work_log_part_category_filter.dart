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
  Widget build(BuildContext context) => ChoiceChip(
    key: ValueKey('work-log-part-category-${category.wireValue}'),
    selected: selected,
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    avatar: HugeIcon(
      icon: workLogPartCategoryIcon(category),
      color: selected ? colors.accent : colors.textSecondary,
      size: 15,
      strokeWidth: 2,
    ),
    label: Text(category.label),
    labelStyle: TextStyle(
      color: selected ? colors.accent : colors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
    labelPadding: const EdgeInsets.only(left: 2, right: 5),
    backgroundColor: colors.surface,
    selectedColor: colors.accent.withValues(alpha: 0.16),
    side: BorderSide(color: selected ? colors.accent : colors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: (_) => onChanged(category),
  );
}
