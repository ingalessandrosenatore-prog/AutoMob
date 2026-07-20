import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../../../core/config/performance_flags.dart';
import '../../../../core/theme/am_theme_colors.dart';
import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/buttons/soft_button.dart';
import '../../domain/entities/work_log_part.dart';
import '../../domain/entities/work_log_row.dart';
import '../work_log_formatters.dart';

class WorkLogDetailPage extends StatelessWidget {
  final WorkLogRow work;

  const WorkLogDetailPage({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final note = work.notes?.trim() ?? '';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onClose: () => Navigator.of(context).maybePop()),
            Expanded(
              child: AmEdgeBlur(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WorkSummary(work: work),
                          const SizedBox(height: 20),
                          _RegisteredBy(work: work),
                          const SizedBox(height: 22),
                          const _SectionLabel('NOTE'),
                          const SizedBox(height: 10),
                          _NoteCard(note: note),
                          const SizedBox(height: 22),
                          const _SectionLabel('PARTI SOSTITUITE'),
                          const SizedBox(height: 10),
                          work.parts.isEmpty
                              ? const _EmptyPartsCard()
                              : _PartsTable(work: work),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final closeButton = SizedBox(
      width: 48,
      height: 48,
      child: AmSoftButton(
        key: const Key('work-log-detail-close'),
        width: 48,
        height: 48,
        color: const Color(0xFF141725),
        icon: HugeIcons.strokeRoundedCancel01,
        onPressed: onClose,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 48, height: 48),
            ),
          ),
          Expanded(
            child: Text(
              'DETTAGLIO INTERVENTO',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: colors.shadow.withValues(alpha: 0.22),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: 'Chiudi dettaglio',
                child: kHeavyEffects
                    ? OCLiquidGlassGroup(
                        settings: const OCLiquidGlassSettings(
                          refractStrength: -0.13,
                          blurRadiusPx: 1.0,
                          specStrength: 0,
                          specWidth: 0,
                          specAngle: 145,
                          blendPx: 20,
                          specPower: 10,
                        ),
                        child: closeButton,
                      )
                    : closeButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkSummary extends StatelessWidget {
  final WorkLogRow work;

  const _WorkSummary({required this.work});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedWrench01,
            color: colors.accent,
            size: 34,
            strokeWidth: 2.2,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workLogTitle(work),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${formatWorkLogDate(work.serviceDate)} · '
                '${formatWorkLogKm(work.serviceKm)}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegisteredBy extends StatelessWidget {
  final WorkLogRow work;

  const _RegisteredBy({required this.work});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final name = work.workshopName?.trim();
    final registeredBy = name?.isNotEmpty == true
        ? name!
        : work.hasWorkshop
        ? 'Officina'
        : 'Tu';
    return _BlueSurface(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Registrato da',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              registeredBy,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final effectiveNote = note.isEmpty ? 'Nessuna nota' : note;
    return _BlueSurface(
      child: Text(
        effectiveNote,
        key: const Key('work-log-detail-note'),
        style: TextStyle(
          color: note.isEmpty ? colors.textSecondary : colors.textPrimary,
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PartsTable extends StatelessWidget {
  final WorkLogRow work;

  const _PartsTable({required this.work});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final borderColor = colors.cardBackground.withValues(alpha: 0.24);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cardBackground.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.17 : 0.1,
          ),
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            for (var index = 0; index < work.parts.length; index++) ...[
              _PartRow(part: work.parts[index]),
              Divider(height: 1, thickness: 1, color: borderColor),
            ],
            _PartsTotal(totalCents: work.partsTotalCents),
          ],
        ),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final WorkLogPart part;

  const _PartRow({required this.part});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final unitPrice = part.unitPriceCents;
    final subtitle = unitPrice == null
        ? '${formatQuantity(part.quantity)} × prezzo non indicato'
        : '${formatQuantity(part.quantity)} × ${formatEuroCents(unitPrice)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (part.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    part.notes!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            part.subtotalCents == null
                ? '—'
                : formatEuroCents(part.subtotalCents!),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartsTotal extends StatelessWidget {
  final int totalCents;

  const _PartsTotal({required this.totalCents});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'TOTALE RICAMBI',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Text(
            formatEuroCents(totalCents),
            key: const Key('work-log-parts-total'),
            style: TextStyle(
              color: colors.cardBackground,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPartsCard extends StatelessWidget {
  const _EmptyPartsCard();

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return _BlueSurface(
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedPackageRemove,
            color: colors.textSecondary,
            size: 22,
            strokeWidth: 1.8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Non sono state registrate parti per questo intervento',
              key: const Key('work-log-detail-empty-parts'),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueSurface extends StatelessWidget {
  final Widget child;

  const _BlueSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: isDark ? 0.17 : 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.cardBackground.withValues(alpha: 0.24),
        ),
      ),
      child: child,
    );
  }
}
