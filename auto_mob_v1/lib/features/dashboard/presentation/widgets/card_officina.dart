import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF232326),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icona Officina (Chiave inglese in box arrotondato)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colore.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.build_outlined,
              color: colore,
              size: 24,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meccanico · $codiceMeccanico',
                  style: const TextStyle(
                    color: Color(0xFF4E5D78),
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
