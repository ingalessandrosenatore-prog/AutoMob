import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../future_work/domain/entities/future_work_summary.dart';
import 'home_future_work_item_data.dart';
import 'home_future_work_timeline_item.dart';

export 'home_future_work_item_data.dart';

class HomeFutureWorkTimeline extends StatelessWidget {
  const HomeFutureWorkTimeline({
    required this.items,
    this.onReportProblem,
    this.onDone,
    this.isUpdating = false,
    super.key,
  });

  const HomeFutureWorkTimeline.demo({
    this.onReportProblem,
    this.onDone,
    this.isUpdating = false,
    super.key,
  }) : items = const [
         HomeFutureWorkItemData(
           title: 'Cambio pastiglie posteriori',
           registeredDateLabel: '13 SET 2026',
         ),
         HomeFutureWorkItemData(
           title: 'Controllo dischi freno',
           registeredDateLabel: '13 SET 2026',
         ),
         HomeFutureWorkItemData(
           title: 'Tagliando periodico',
           registeredDateLabel: '12 SET 2026',
         ),
       ];

  factory HomeFutureWorkTimeline.fromSummaries({
    required List<FutureWorkSummary> summaries,
    VoidCallback? onReportProblem,
    ValueChanged<String>? onDone,
    bool isUpdating = false,
    Key? key,
  }) => HomeFutureWorkTimeline(
    key: key,
    items: summaries.map(HomeFutureWorkItemData.fromSummary).toList(),
    onReportProblem: onReportProblem,
    onDone: onDone,
    isUpdating: isUpdating,
  );

  final List<HomeFutureWorkItemData> items;
  final VoidCallback? onReportProblem;
  final ValueChanged<String>? onDone;
  final bool isUpdating;

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
                      HomeFutureWorkTimelineItem(
                        index: index,
                        isUpdating: isUpdating,
                        item: item,
                        onDone: item.recordId != null && onDone != null
                            ? () => onDone!(item.recordId!)
                            : null,
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
