import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import 'home_future_work_item_data.dart';

class HomeFutureWorkTimelineItem extends StatelessWidget {
  const HomeFutureWorkTimelineItem({
    super.key,
    this.onDone,
    this.isUpdating = false,
    required this.index,
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final VoidCallback? onDone;
  final bool isUpdating;
  final int index;
  final HomeFutureWorkItemData item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final markerColor = isFirst ? colors.accent : colors.textSecondary;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: ValueKey('future-work-marker-$index'),
              width: 22,
              child: CustomPaint(
                painter: _TimelineMarkerPainter(
                  color: markerColor,
                  lineColor: colors.borderHighlight,
                  isFirst: isFirst,
                  isLast: isLast,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 1, bottom: isLast ? 8 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.registeredDateLabel}  ·  ${item.kmLabel}',
                      key: ValueKey('report-date-km-${item.recordId}'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.45,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    if (item.warningLights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      AmWarningLights(
                        lights: [
                          for (final light in item.warningLights)
                            AmWarningLightData(
                              code: light.code,
                              color: light.color,
                              flashing: light.flashing,
                              onboardMessage: item.onboardMessage,
                              description: item.title,
                            ),
                        ],
                      ),
                    ],
                    if (onDone != null)
                      TextButton.icon(
                        key: ValueKey('done-${item.recordId}'),
                        onPressed: isUpdating ? null : onDone,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Segna come risolta'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineMarkerPainter extends CustomPainter {
  const _TimelineMarkerPainter({
    required this.color,
    required this.lineColor,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final Color lineColor;
  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(6, 7);
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.72)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, isFirst ? center.dy : 0),
      Offset(center.dx, isLast ? center.dy : size.height),
      linePaint,
    );
    canvas.drawCircle(center, isFirst ? 5 : 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TimelineMarkerPainter oldDelegate) =>
      color != oldDelegate.color ||
      lineColor != oldDelegate.lineColor ||
      isFirst != oldDelegate.isFirst ||
      isLast != oldDelegate.isLast;
}
