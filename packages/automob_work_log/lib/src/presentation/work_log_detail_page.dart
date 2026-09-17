import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_type.dart';
import 'work_log_detail_body.dart';
import 'work_log_top_app_bar.dart';

class WorkLogDetailPage extends StatelessWidget {
  const WorkLogDetailPage({
    required this.entry,
    this.currentKm,
    this.onBackPressed,
    this.onAddPressed,
    super.key,
  });

  final WorkLogEntry entry;
  final int? currentKm;
  final VoidCallback? onBackPressed;
  final ValueChanged<WorkLogType>? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final infoStrength = Theme.of(context).brightness == Brightness.dark
        ? 0.42
        : 0.34;
    final workType = WorkLogType.tryFromWire(entry.type) ?? WorkLogType.other;
    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
        centerTitle: true,
        toolbarHeight: WorkLogTopAppBar.contentHeight,
        leadingWidth: 69,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
          child: WorkLogGlassControl(
            child: AmSoftButton(
              key: const Key('work-log-detail-back'),
              width: AmControlMetrics.circularButtonVisualSize,
              height: AmControlMetrics.circularButtonVisualSize,
              color: colors.background.withValues(alpha: 0.25),
              icon: HugeIcons.strokeRoundedArrowLeft01,
              iconColor: colors.textPrimary,
              iconSize: AmControlMetrics.circularButtonIconSize,
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          entry.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.8,
          ),
        ),
      ),
      body: DecoratedBox(
        key: const Key('work-log-detail-background'),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.18,
            colors: [
              Color.alphaBlend(
                colors.info.withValues(alpha: infoStrength),
                colors.background,
              ),
              colors.background,
            ],
            stops: const [0, 0.88],
          ),
        ),
        child: WorkLogDetailBody(
          entry: entry,
          currentKm: currentKm,
          topPadding:
              MediaQuery.paddingOf(context).top +
              WorkLogTopAppBar.contentHeight +
              10,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: AmMainFab(
              key: const Key('work-log-detail-add'),
              width: double.infinity,
              height: 56,
              label: 'AGGIUNGI ${workType.label.toUpperCase()}',
              color: colors.accent,
              fontSize: 14,
              onPressed: () => onAddPressed?.call(workType),
            ),
          ),
        ),
      ),
    );
  }
}
