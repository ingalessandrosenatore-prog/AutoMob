import 'package:flutter/material.dart';

/// Card KPI per la manutenzione (es. Tagliando, Distribuzione).
/// Mostra l'icona, la percentuale, i km rimanenti e i dettagli della scadenza.
class AmMaintenanceKpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int remainingKm;
  final int nextServiceKm;
  final String? lastServiceDate;
  final double percentage; // Valore da 0 a 100

  const AmMaintenanceKpiCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.remainingKm,
    required this.nextServiceKm,
    required this.percentage,
    this.lastServiceDate,
  });

  @override
  Widget build(BuildContext context) {
    // Formattazione chilometri con separatore (es. 74.770)
    String formatKm(int km) {
      return km.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121214), // Sfondo scuro profondo
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Superiore: Icona, Titolo e Percentuale
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chilometri Rimasti
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              children: [
                const TextSpan(text: 'Rimasti : '),
                TextSpan(text: '${formatKm(remainingKm)} km'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Info Secondarie (Prossimo e Ultimo)
          Text(
            'Richiamo a ${formatKm(nextServiceKm)} km ${lastServiceDate != null
                ? "· Ultima: $lastServiceDate"
                : ""}',
            style: const TextStyle(
              color: Color(0xFF636366),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Barra della Percentuale
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}