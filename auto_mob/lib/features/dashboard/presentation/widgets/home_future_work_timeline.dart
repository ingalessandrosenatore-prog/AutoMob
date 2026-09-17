import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../future_work/domain/entities/future_work_summary.dart';

class HomeFutureWorkItemData {
  const HomeFutureWorkItemData({
    required this.title,
    required this.registeredDateLabel,
    required this.reminderDateLabel,
  });

  final String title;
  final String registeredDateLabel;
  final String reminderDateLabel;

  factory HomeFutureWorkItemData.fromSummary(FutureWorkSummary summary) =>
      HomeFutureWorkItemData(
        title: summary.description,
        registeredDateLabel: _formatDate(summary.registeredAt),
        reminderDateLabel: _formatDate(summary.reminderDate),
      );
}

class HomeFutureWorkTimeline extends StatelessWidget {
  const HomeFutureWorkTimeline({
    required this.items,
    this.onReportProblem,
    super.key,
  });

  const HomeFutureWorkTimeline.demo({this.onReportProblem, super.key})
    : items = const [
        HomeFutureWorkItemData(
          title: 'Cambio pastiglie posteriori',
          registeredDateLabel: '13 SET 2026',
          reminderDateLabel: '18 SET 2026',
        ),
        HomeFutureWorkItemData(
          title: 'Controllo dischi freno',
          registeredDateLabel: '13 SET 2026',
          reminderDateLabel: '04 OTT 2026',
        ),
        HomeFutureWorkItemData(
          title: 'Tagliando periodico',
          registeredDateLabel: '12 SET 2026',
          reminderDateLabel: '22 NOV 2026',
        ),
      ];

  factory HomeFutureWorkTimeline.fromSummaries({
    required List<FutureWorkSummary> summaries,
    VoidCallback? onReportProblem,
    Key? key,
  }) => HomeFutureWorkTimeline(
    key: key,
    items: summaries.map(HomeFutureWorkItemData.fromSummary).toList(),
    onReportProblem: onReportProblem,
  );

  final List<HomeFutureWorkItemData> items;
  final VoidCallback? onReportProblem;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 22, 9, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAVORI FUTURI',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: colors.accent,
                size: 22,
                strokeWidth: 2.2,
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.borderHighlight, width: 1.5),
              boxShadow: colors.cardShadows,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                children: [
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Nessuna segnalazione aperta',
                        key: const ValueKey('future-work-empty'),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    for (final (index, item) in items.indexed)
                      _FutureWorkTimelineItem(
                        index: index,
                        item: item,
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
                      ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 220,
                    height: 50,
                    child: FilledButton(
                      key: const ValueKey('report-problem-button'),
                      onPressed: onReportProblem,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onMedia,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Segnala problema'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = [
    'GEN',
    'FEB',
    'MAR',
    'APR',
    'MAG',
    'GIU',
    'LUG',
    'AGO',
    'SET',
    'OTT',
    'NOV',
    'DIC',
  ];
  final day = value.day.toString().padLeft(2, '0');
  return '$day ${months[value.month - 1]} ${value.year}';
}

class _FutureWorkTimelineItem extends StatelessWidget {
  const _FutureWorkTimelineItem({
    required this.index,
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

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
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: item.registeredDateLabel),
                          const TextSpan(text: '  ·  '),
                          TextSpan(
                            text:
                                'DA EFFETTUARE ENTRO ${item.reminderDateLabel}',
                            style: TextStyle(color: colors.accent),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.78),
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
