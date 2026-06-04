import 'package:flutter/material.dart';

/// Card KPI tridimensionale per la manutenzione.
/// Mostra lo stato, la valutazione di affidabilità e il pulsante per i dettagli.
class AmMaintenanceKpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int remainingKm;
  final double percentage; // Valore da 0 a 100
  final int offersCount;
  final int reviewCount;
  final VoidCallback? onTap;

  const AmMaintenanceKpiCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.remainingKm,
    required this.percentage,
    this.offersCount = 0,
    this.reviewCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Formattazione chilometri con separatore
    String formatKm(int km) {
      final sign = km < 0 ? "-" : "";
      final absoluteKm = km.abs();
      final formatted = absoluteKm.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      return "$sign$formatted";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF232326), // Sfondo scuro profondo
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          // Ombra esterna profonda per effetto 3D
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          // Sottile riflesso sul bordo superiore
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contenuto Principale
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Icona + Label
                    Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Chilometri Rimasti
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                        children: [
                          const TextSpan(text: 'Rimasti: '),
                          TextSpan(
                            text: '${formatKm(remainingKm)} KM',
                            style: TextStyle(color: remainingKm < 0 ? Colors.redAccent : Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Segmented Rating Bar
                    _SegmentedProgressBar(percentage: percentage, color: color),

                  ],
                ),
              ),
            ),
            // Sezione Laterale Clickable (Chevron)
            Material(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.3),
                      size: 28,
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

class _SegmentedProgressBar extends StatelessWidget {
  final double percentage;
  final Color color;

  const _SegmentedProgressBar({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final segmentThreshold = (index + 1) * 25;
        final isActive = percentage >= segmentThreshold - 12; // Un po' di tolleranza

        return Expanded(
          child: Container(
            height: 12,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
