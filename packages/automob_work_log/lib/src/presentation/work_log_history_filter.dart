import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../domain/work_log_type.dart';

class WorkLogHistoryFilter extends StatelessWidget {
  const WorkLogHistoryFilter({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  final WorkLogType? selectedType;
  final ValueChanged<WorkLogType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return SmartEdge(
      blur: true,
      opacity: 0.2,
      fallbackTint: colors.background,
      edges: [
        _horizontalEdge(EdgeType.leftEdge, colors.background),
        _horizontalEdge(EdgeType.rightEdge, colors.background),
      ],
      child: SingleChildScrollView(
        key: const Key('work-log-history-filters'),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Tutti',
              wireValue: 'all',
              selected: selectedType == null,
              colors: colors,
              onSelected: () => onChanged(null),
            ),
            for (final type in WorkLogType.values) ...[
              const SizedBox(width: 8),
              _FilterChip(
                label: type.label,
                wireValue: type.wireValue,
                selected: selectedType == type,
                colors: colors,
                onSelected: () => onChanged(type),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

EdgeBlur _horizontalEdge(EdgeType type, Color background) => EdgeBlur(
  type: type,
  size: 10,
  tintColor: background,
  sigma: 10,
  controlPoints: [
    ControlPoint(position: 0.2, type: ControlPointType.visible),
    ControlPoint(position: 1, type: ControlPointType.transparent),
  ],
);

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.wireValue,
    required this.selected,
    required this.colors,
    required this.onSelected,
  });

  final String label;
  final String wireValue;
  final bool selected;
  final AmThemeColors colors;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    key: ValueKey('work-log-history-filter-$wireValue'),
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    backgroundColor: colors.surface,
    selectedColor: colors.surface,
    side: BorderSide(color: selected ? colors.accent : colors.border),
    shape: const StadiumBorder(),
    labelStyle: TextStyle(
      color: selected ? colors.accent : colors.textSecondary,
      fontSize: 13,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    onSelected: (_) => onSelected(),
  );
}
