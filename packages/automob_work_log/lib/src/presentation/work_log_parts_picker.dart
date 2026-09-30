import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
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
    super.key,
  });

  final List<WorkLogPartDraft> selectedParts;
  final String query;
  final WorkLogPartCategory? selectedCategory;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<WorkLogPartCategory> onCategoryChanged;
  final ValueChanged<int> onPartToggled;

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CERCA RICAMBIO',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('work-log-parts-search'),
                onChanged: onQueryChanged,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surface,
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: colors.textSecondary,
                    size: 16,
                    strokeWidth: 1.5,
                  ),
                  hintText: 'Nome del ricambio',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colors.accent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              WorkLogPartCategoryFilter(
                selectedCategory: selectedCategory,
                onChanged: onCategoryChanged,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            key: const Key('work-log-parts-grid'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: .82,
            ),
            itemCount: parts.length,
            itemBuilder: (_, index) {
              final part = parts[index];
              return _PartTile(
                key: ValueKey('work-log-part-${part.key}'),
                label: part.value.name,
                icon: workLogPartIcon(part.key),
                selected: selectedIds.contains(part.key),
                onTap: () => onPartToggled(part.key),
              );
            },
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
    super.key,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? colors.accent.withValues(alpha: .22)
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colors.accent : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: selected ? 1.12 : 1,
                  child: HugeIcon(
                    icon: icon,
                    color: selected ? colors.accent : colors.textSecondary,
                    size: 22,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
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
