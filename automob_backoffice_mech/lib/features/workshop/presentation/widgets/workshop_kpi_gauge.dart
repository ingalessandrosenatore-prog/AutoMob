import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// Adattatore dell'officina sul tachimetro condiviso tra le due app.
class WorkshopKpiGauge extends StatelessWidget {
  const WorkshopKpiGauge({
    super.key,
    required this.label,
    required this.value,
    required this.maximum,
    required this.valueFormatter,
  });

  final String label;
  final num value;
  final num maximum;
  final String Function(num value) valueFormatter;

  @override
  Widget build(BuildContext context) => AmKpiGauge(
    label: label,
    value: value,
    maximum: maximum,
    valueFormatter: valueFormatter,
  );
}
