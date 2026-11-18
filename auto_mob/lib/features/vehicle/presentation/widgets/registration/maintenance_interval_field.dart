import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MaintenanceIntervalField extends StatelessWidget {
  const MaintenanceIntervalField({
    super.key,
    required this.controller,
    this.label = 'Intervallo',
    this.years = false,
    this.onEdited,
  });

  final TextEditingController controller;
  final String label;
  final bool years;
  final VoidCallback? onEdited;

  static final _kmValues = [
    for (int step = 0; step <= 60; step++) step * 1000,
    for (int step = 65; step <= 150; step += 5) step * 1000,
  ];
  static final _yearValues = [for (int year = 1; year <= 20; year++) year];

  static int? read(TextEditingController controller, {bool years = false}) {
    final parsed = int.tryParse(controller.text);
    if (parsed == null) return null;
    final values = years ? _yearValues : _kmValues;
    return values[_closestIndex(values, parsed)];
  }

  static int _closestIndex(List<int> values, int value) {
    if (value <= values.first) return 0;
    for (int index = 1; index < values.length; index++) {
      if (value <= values[index]) {
        return value - values[index - 1] < values[index] - value
            ? index - 1
            : index;
      }
    }
    return values.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final values = years ? _yearValues : _kmValues;
    final unit = years ? 'anni' : 'km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) => SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 10,
                    trackShape: const RoundedRectSliderTrackShape(),
                    activeTrackColor: colors.accent,
                    inactiveTrackColor: colors.textPrimary.withValues(
                      alpha: .13,
                    ),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    overlayColor: colors.accent.withValues(alpha: .14),
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Semantics(
                    label: label,
                    child: Slider(
                      max: (values.length - 1).toDouble(),
                      divisions: values.length - 1,
                      value: _closestIndex(
                        values,
                        int.tryParse(value.text) ?? values.first,
                      ).toDouble(),
                      semanticFormatterCallback: (index) =>
                          '${values[index.round()]} $unit',
                      onChanged: (index) {
                        controller.text = values[index.round()].toString();
                        onEdited?.call();
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: years ? 68 : 106,
              child: Focus(
                onFocusChange: (focused) {
                  if (focused) return;
                  final normalized = read(controller, years: years);
                  if (normalized != null) {
                    controller.text = normalized.toString();
                  }
                },
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onEdited?.call(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(years ? 2 : 6),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '—',
                    suffixText: unit,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
