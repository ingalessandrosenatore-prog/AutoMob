import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import 'mechanic_vehicle_card_work_models.dart';

class MechanicVehicleCardWorksDrawer extends StatelessWidget {
  const MechanicVehicleCardWorksDrawer({
    required this.mandatoryWorks,
    required this.userProblems,
    this.onOpenVehicle,
    super.key,
  });

  final List<MechanicMandatoryWorkItemData> mandatoryWorks;
  final List<MechanicUserProblemItemData> userProblems;
  final VoidCallback? onOpenVehicle;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorksSectionHeader(
            title: 'SCADENZE OBBLIGATORIE',
            color: colors.accent,
          ),
          const SizedBox(height: 8),
          if (mandatoryWorks.isEmpty)
            _EmptyTimelineRow(
              label: 'Nessuna scadenza obbligatoria',
              color: colors.accent,
            )
          else
            for (final (index, work) in mandatoryWorks.indexed)
              _MandatoryWorkTimelineRow(
                index: index,
                work: work,
                isFirst: index == 0,
                isLast: index == mandatoryWorks.length - 1,
              ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              key: const Key('mechanic-vehicle-works-divider'),
              height: 1,
              child: ColoredBox(
                color: colors.borderHighlight.withValues(alpha: 0.75),
              ),
            ),
          ),
          _WorksSectionHeader(title: 'SEGNALAZIONI UTENTE', color: colors.info),
          const SizedBox(height: 8),
          if (userProblems.isEmpty)
            _EmptyTimelineRow(
              label: 'Nessuna segnalazione utente',
              color: colors.info,
            )
          else
            for (final (index, problem) in userProblems.indexed)
              _UserProblemTimelineRow(
                index: index,
                problem: problem,
                isFirst: index == 0,
                isLast: index == userProblems.length - 1,
              ),
          if (onOpenVehicle != null) ...[
            const SizedBox(height: 10),
            Semantics(
              button: true,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  key: const Key('mechanic-vehicle-open-details'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenVehicle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Apri storico lavori',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorksSectionHeader extends StatelessWidget {
  const _WorksSectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const SizedBox.square(dimension: 6),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
        ),
      ),
    ],
  );
}

class _EmptyTimelineRow extends StatelessWidget {
  const _EmptyTimelineRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 24,
            child: CustomPaint(
              painter: _WorkTimelineMarkerPainter(
                color: color.withValues(alpha: 0.45),
                lineColor: colors.borderHighlight,
                isFirst: true,
                isLast: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MandatoryWorkTimelineRow extends StatelessWidget {
  const _MandatoryWorkTimelineRow({
    required this.index,
    required this.work,
    required this.isFirst,
    required this.isLast,
  });

  final int index;
  final MechanicMandatoryWorkItemData work;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: ValueKey('mandatory-work-marker-$index'),
            width: 22,
            child: CustomPaint(
              painter: _WorkTimelineMarkerPainter(
                color: colors.accent,
                lineColor: colors.accent.withValues(alpha: 0.45),
                isFirst: isFirst,
                isLast: isLast,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.build_circle_outlined,
                      color: colors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        if (work.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            work.subtitle,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserProblemTimelineRow extends StatelessWidget {
  const _UserProblemTimelineRow({
    required this.index,
    required this.problem,
    required this.isFirst,
    required this.isLast,
  });

  final int index;
  final MechanicUserProblemItemData problem;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: ValueKey('user-problem-marker-$index'),
            width: 22,
            child: CustomPaint(
              painter: _WorkTimelineMarkerPainter(
                color: colors.info,
                lineColor: colors.info.withValues(alpha: 0.45),
                isFirst: isFirst,
                isLast: isLast,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (problem.headerLabel.isNotEmpty) ...[
                    Text(
                      problem.headerLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (problem.warningLights.isNotEmpty)
                    for (final (lightIndex, light)
                        in problem.warningLights.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: lightIndex < problem.warningLights.length - 1
                              ? 8
                              : 0,
                        ),
                        child: _WarningLightProblemRow(
                          light: light,
                          description: problem.description,
                          showDescription: lightIndex == 0,
                        ),
                      )
                  else
                    _TextOnlyProblemRow(
                      title: problem.description.isNotEmpty
                          ? problem.description
                          : problem.onboardMessage.isNotEmpty
                          ? problem.onboardMessage
                          : 'Segnalazione cliente',
                    ),
                  if (problem.onboardMessage.isNotEmpty &&
                      problem.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Computer di bordo: ${problem.onboardMessage}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningLightProblemRow extends StatelessWidget {
  const _WarningLightProblemRow({
    required this.light,
    required this.description,
    required this.showDescription,
  });

  final AmWarningLightData light;
  final String description;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final trimmedDescription = description.trim();
    final isGenericLight = light.code == 'OTHER';
    final primaryTitle = isGenericLight && trimmedDescription.isNotEmpty
        ? trimmedDescription
        : light.label;
    final secondaryText =
        showDescription &&
            trimmedDescription.isNotEmpty &&
            trimmedDescription.toLowerCase() != primaryTitle.toLowerCase()
        ? trimmedDescription
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AmWarningLight(light: light, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primaryTitle,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (secondaryText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  secondaryText,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TextOnlyProblemRow extends StatelessWidget {
  const _TextOnlyProblemRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, color: colors.info, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkTimelineMarkerPainter extends CustomPainter {
  const _WorkTimelineMarkerPainter({
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
    const center = Offset(7, 9);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    if (!isFirst || !isLast) {
      canvas.drawLine(
        Offset(center.dx, isFirst ? center.dy : 0),
        Offset(center.dx, isLast ? center.dy : size.height),
        linePaint,
      );
    }
    canvas.drawCircle(center, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WorkTimelineMarkerPainter oldDelegate) =>
      color != oldDelegate.color ||
      lineColor != oldDelegate.lineColor ||
      isFirst != oldDelegate.isFirst ||
      isLast != oldDelegate.isLast;
}
