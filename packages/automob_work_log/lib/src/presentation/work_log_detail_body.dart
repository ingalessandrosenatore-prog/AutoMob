import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_parts_catalog.dart';
import 'work_log_detail_entrance.dart';
import 'work_log_detail_parts_table.dart';

class WorkLogDetailBody extends StatelessWidget {
  const WorkLogDetailBody({
    required this.entry,
    this.currentKm,
    this.topPadding = 18,
    super.key,
  });

  final WorkLogEntry entry;
  final int? currentKm;
  final double topPadding;

  @override
  Widget build(BuildContext context) => WorkLogDetailEntrance(
    builder: (context, entrance) => AmEdgeBlur(
      child: SingleChildScrollView(
        key: const Key('work-log-detail-scroll'),
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 116),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSummary(
                  entry: entry,
                  currentKm: currentKm,
                  entrance: entrance,
                ),
                const SizedBox(height: 18),
                _ProgressMarks(
                  remainingKm: entry.remainingKmAt(currentKm),
                  intervalKm: entry.intervalKm,
                  entrance: entrance,
                ),
                const SizedBox(height: 36),
                _TextEntrance(
                  animation: workLogEntranceInterval(entrance, 0.18, 0.78),
                  child: _MaintenanceFacts(
                    entry: entry,
                    currentKm: currentKm,
                    entrance: entrance,
                  ),
                ),
                const SizedBox(height: 34),
                _TextEntrance(
                  animation: workLogEntranceInterval(entrance, 0.38, 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PARTI CAMBIATE E COSTO',
                        style: TextStyle(
                          color: AmThemeColors.of(context).textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      WorkLogDetailPartsTable(entry: entry),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.entry,
    required this.currentKm,
    required this.entrance,
  });

  final WorkLogEntry entry;
  final int? currentKm;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final remainingKm = entry.remainingKmAt(currentKm);
    final expired = entry.isExpiredAt(currentKm);
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = math.min(constraints.maxWidth * 0.7, 390.0);
        return SizedBox(
          height: 330,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -34,
                top: 4,
                width: imageWidth,
                child: SlideTransition(
                  key: const Key('work-log-detail-photo-entrance'),
                  position: Tween<Offset>(
                    begin: const Offset(0.62, 0),
                    end: Offset.zero,
                  ).animate(workLogEntranceInterval(entrance, 0, 0.7)),
                  child: Image.asset(
                    _assetForEntry(entry),
                    key: const Key('work-log-detail-hero'),
                    package: 'automob_work_log',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 44,
                width: constraints.maxWidth * 0.48,
                child: _TextEntrance(
                  animation: workLogEntranceInterval(entrance, 0.08, 0.62),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (expired != null) ...[
                        const SizedBox(height: 12),
                        _StatusPill(expired: expired),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KM rimanenti',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _AnimatedRemainingKm(
                      remainingKm: remainingKm,
                      entrance: entrance,
                      key: const Key('work-log-detail-remaining-km'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 39,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkIcon extends StatelessWidget {
  const _WorkIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.42)),
    ),
    alignment: Alignment.center,
    child: HugeIcon(
      icon: HugeIcons.strokeRoundedTools,
      color: color,
      size: 28,
      strokeWidth: 2,
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.expired});

  final bool expired;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final color = expired ? const Color(0xFFFF8A00) : colors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: expired
                ? HugeIcons.strokeRoundedAlert01
                : HugeIcons.strokeRoundedCheckmarkBadge01,
            color: color,
            size: 17,
            strokeWidth: 2,
          ),
          const SizedBox(width: 7),
          Text(
            expired ? 'Scaduto' : 'Regolare',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProgressMarks extends StatelessWidget {
  const _ProgressMarks({
    required this.remainingKm,
    required this.intervalKm,
    required this.entrance,
  });

  final int? remainingKm;
  final int? intervalKm;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final safeInterval = intervalKm ?? 0;
    final targetRatio = safeInterval <= 0 || remainingKm == null
        ? 0.0
        : (math.max(remainingKm!, 0) / safeInterval).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, _) {
        final animatedRatio =
            targetRatio * Curves.easeOutCubic.transform(entrance.value);
        final activeCount = math.min(6, (animatedRatio * 6).floor());
        return Row(
          children: List.generate(
            6,
            (index) => Expanded(
              child: Container(
                key: ValueKey('work-log-detail-progress-$index'),
                height: 6,
                margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                decoration: BoxDecoration(
                  color: index < activeCount
                      ? colors.accent
                      : colors.border.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaintenanceFacts extends StatelessWidget {
  const _MaintenanceFacts({
    required this.entry,
    required this.currentKm,
    required this.entrance,
  });

  final WorkLogEntry entry;
  final int? currentKm;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    final remainingKm = entry.remainingKmAt(currentKm);
    return Column(
      children: [
        _FactRow(
          icon: HugeIcons.strokeRoundedCalendar01,
          color: AmThemeColors.of(context).accent,
          label: 'Effettuato il',
          value:
              '${_formatDate(entry.serviceDate)}  •  ${_formatNumber(entry.serviceKm)} KM',
        ),
        const SizedBox(height: 26),
        _FactRow(
          icon: HugeIcons.strokeRoundedClock01,
          color: const Color(0xFF8B4DFF),
          label: 'Intervallo',
          value: entry.hasKmDeadline
              ? '${_formatNumber(entry.intervalKm!)} KM'
              : '-',
        ),
        const SizedBox(height: 26),
        _FactRow(
          icon: HugeIcons.strokeRoundedDashboardSpeed02,
          color: const Color(0xFFFF8A00),
          label: 'Mancano',
          valueWidget: _AnimatedRemainingKm(
            remainingKm: remainingKm,
            entrance: entrance,
            style: TextStyle(
              color: AmThemeColors.of(context).textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.color,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final dynamic icon;
  final Color color;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: HugeIcon(icon: icon, color: color, size: 29, strokeWidth: 2),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              valueWidget ??
                  Text(
                    value!,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedRemainingKm extends AnimatedWidget {
  const _AnimatedRemainingKm({
    required this.remainingKm,
    required Animation<double> entrance,
    required this.style,
    super.key,
  }) : super(listenable: entrance);

  final int? remainingKm;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final entrance = listenable as Animation<double>;
    final target = remainingKm == null ? null : math.max(remainingKm!, 0);
    final value = target == null
        ? null
        : (target * Curves.easeOutCubic.transform(entrance.value)).round();
    return Text(
      value == null ? '-' : '${_formatNumber(value)} KM',
      key: key,
      style: style,
    );
  }
}

class _TextEntrance extends StatelessWidget {
  const _TextEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  );
}

String _assetForEntry(WorkLogEntry entry) {
  final byType = switch (entry.type) {
    'distribuzione' || 'motore' => 'assets/images/motor_check.png',
    'pneumatici_cambio' ||
    'pneumatici_inversione' => 'assets/images/gomme_check.png',
    'freni' => 'assets/images/brakes_check.png',
    'telaio' => 'assets/images/chassis_check.png',
    'elettronica' || 'batteria' => 'assets/images/electronics_check.png',
    'cambio' => 'assets/images/gearbox_check.png',
    _ => null,
  };
  if (byType != null) return byType;

  for (final part in entry.parts) {
    final byCategory = _assetForCategory(part.category);
    if (byCategory != null) return byCategory;
  }
  return 'assets/images/car_check.png';
}

String? _assetForCategory(WorkLogPartCategory? category) => switch (category) {
  WorkLogPartCategory.engine => 'assets/images/motor_check.png',
  WorkLogPartCategory.tires => 'assets/images/gomme_check.png',
  WorkLogPartCategory.brakes => 'assets/images/brakes_check.png',
  WorkLogPartCategory.chassis => 'assets/images/chassis_check.png',
  WorkLogPartCategory.electronics => 'assets/images/electronics_check.png',
  WorkLogPartCategory.gearbox => 'assets/images/gearbox_check.png',
  WorkLogPartCategory.vehicle || null => null,
};

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
