import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';

/// Card per visualizzare l'officina di riferimento.
/// Include l'icona, il nome, il codice meccanico e lo stato (es. Attivo).
class AmWorkshopCard extends StatelessWidget {
  final String nomeOfficina;
  final String codiceMeccanico;
  final String stato;
  final Color colore;

  const AmWorkshopCard({
    super.key,
    required this.nomeOfficina,
    required this.codiceMeccanico,
    required this.stato,
    required this.colore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icona Officina (Chiave inglese in box arrotondato)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colore.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedWrench01,
              color: colore,
              size: 24,
              strokeWidth: 2.2,
            ),
          ),
          const SizedBox(width: 16),
          // Info Officina (Nome e Codice)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomeOfficina,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meccanico · $codiceMeccanico',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Indicatore di Stato (Punto + Testo)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colore,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stato,
                style: TextStyle(
                  color: colore,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
