import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// Adattatore dell'officina sul selettore a cambio condiviso.
class WorkshopGearPeriodSelector extends StatelessWidget {
  const WorkshopGearPeriodSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(labels.length == 3),
       assert(selectedIndex >= 0 && selectedIndex < 3);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => AmGearPeriodSelector(
    labels: labels,
    selectedIndex: selectedIndex,
    onChanged: onChanged,
    semanticLabel: 'Periodo statistiche officina',
  );
}
