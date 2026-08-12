import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_part.dart';

/// Contenuto originale AutoMob del dettaglio. Le app forniscono solo l'app bar.
class WorkLogDetailBody extends StatelessWidget {
  const WorkLogDetailBody({required this.entry, super.key});

  final WorkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final note = entry.notes?.trim() ?? '';
    return AmEdgeBlur(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkSummary(entry: entry),
                const SizedBox(height: 20),
                _RegisteredBy(entry: entry),
                const SizedBox(height: 22),
                const _SectionLabel('NOTE'),
                const SizedBox(height: 10),
                _NoteCard(note: note),
                const SizedBox(height: 22),
                const _SectionLabel('PARTI SOSTITUITE'),
                const SizedBox(height: 10),
                entry.parts.isEmpty
                    ? const _EmptyPartsCard()
                    : _PartsTable(entry: entry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkSummary extends StatelessWidget {
  const _WorkSummary({required this.entry});
  final WorkLogEntry entry;

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
                entry.title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_formatDate(entry.serviceDate)} · ${_formatKm(entry.serviceKm)}',
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
  const _RegisteredBy({required this.entry});
  final WorkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
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
              _registeredBy(entry),
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
  const _SectionLabel(this.label);
  final String label;

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
  const _NoteCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return _BlueSurface(
      child: Text(
        note.isEmpty ? 'Nessuna nota' : note,
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
  const _PartsTable({required this.entry});
  final WorkLogEntry entry;

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
            for (var index = 0; index < entry.parts.length; index++) ...[
              _PartRow(part: entry.parts[index]),
              Divider(height: 1, thickness: 1, color: borderColor),
            ],
            _PartsTotal(totalCents: entry.partsTotalCents),
          ],
        ),
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({required this.part});
  final WorkLogPart part;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final subtitle = part.unitPriceCents == null
        ? '${_formatQuantity(part.quantity)} × prezzo non indicato'
        : '${_formatQuantity(part.quantity)} × ${_formatEuro(part.unitPriceCents!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
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
            part.subtotalCents == null ? '—' : _formatEuro(part.subtotalCents!),
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
  const _PartsTotal({required this.totalCents});
  final int totalCents;

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
            _formatEuro(totalCents),
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
  const _BlueSurface({required this.child});
  final Widget child;

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

String _registeredBy(WorkLogEntry entry) {
  final name = entry.workshopName?.trim();
  return name?.isNotEmpty == true
      ? name!
      : entry.hasWorkshop
      ? 'Officina'
      : 'Tu';
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
String _formatKm(int value) => '$value km';
String _formatEuro(int cents) => '${(cents / 100).toStringAsFixed(2)} €';
String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
