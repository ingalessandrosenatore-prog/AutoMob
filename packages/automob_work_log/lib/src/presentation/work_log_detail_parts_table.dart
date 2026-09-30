import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../domain/work_log_entry.dart';
import '../domain/work_log_part.dart';

class WorkLogDetailPartsTable extends StatelessWidget {
  const WorkLogDetailPartsTable({required this.entry, super.key});

  final WorkLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final border = colors.border.withValues(alpha: 0.75);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        key: const Key('work-log-detail-parts-table-surface'),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            _Header(border: border),
            if (entry.parts.isEmpty)
              const _EmptyRow()
            else
              for (final part in entry.parts) _PartRow(part: part),
            _TotalRow(totalCents: entry.partsTotalCents),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.border});

  final Color border;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.09),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Label('PARTE CAMBIATA', color: colors.textSecondary),
          ),
          _Label('COSTO', color: colors.textSecondary),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              part.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            part.subtotalCents == null ? '-' : _formatEuro(part.subtotalCents!),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    child: Text(
      'Nessuna parte registrata',
      key: const Key('work-log-detail-empty-parts'),
      style: TextStyle(color: AmThemeColors.of(context).textSecondary),
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.totalCents});

  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: _Label('TOTALE RICAMBI', color: colors.textSecondary),
          ),
          Text(
            _formatEuro(totalCents),
            key: const Key('work-log-parts-total'),
            style: TextStyle(
              color: colors.accent,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.value, {required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
    ),
  );
}

String _formatEuro(int cents) => '${(cents / 100).toStringAsFixed(2)} €';
