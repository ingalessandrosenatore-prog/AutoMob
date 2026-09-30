import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// Formats the signed variation supplied by the overview.
class WorkshopMetricTrend extends StatelessWidget {
  const WorkshopMetricTrend({
    required this.value,
    this.isPercentage = false,
    super.key,
  });

  final num value;
  final bool isPercentage;

  @override
  Widget build(BuildContext context) {
    final color = AmThemeColors.of(context).accent;
    final direction = value > 0
        ? 'in più'
        : value < 0
        ? 'in meno'
        : 'invariato';
    final amount = value.abs().toString().replaceAll('.', ',');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$amount${isPercentage ? ' %' : ''} $direction '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              value > 0
                  ? Icons.north_east_rounded
                  : value < 0
                  ? Icons.south_east_rounded
                  : Icons.east_rounded,
              color: color,
              size: 14,
            ),
          ),
        ],
      ),
      style: TextStyle(
        color: color,
        fontSize: 10,
        height: 1.4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
