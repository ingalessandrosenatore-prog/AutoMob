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
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C2C2E), // Grigio scuro leggermente più chiaro
            Color(0xEF151414), // Grigio molto scuro
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Icona di Sfondo (Watermark)
            Positioned(
              right: -30,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.2, // Leggera rotazione stile design
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                    ).createShader(bounds);
                  },
                  child: Icon(
                    icon,
                    size: 160,
                    // Il colore base viene sovrascritto dallo ShaderMask
                  ),
                ),
              ),
            ),
            // Contenuto Interattivo
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Contenuto Principale
                      Expanded(
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
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Chilometri Rimasti
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${formatKm(remainingKm)} ',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: remainingKm < 0
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                ),
                                Text(
                                  "KM Rimasti",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Segmented Rating Bar
                            _SegmentedProgressBar(
                                percentage: percentage, color: color),
                          ],
                        ),
                      ),
                      // Freccia di navigazione (Chevron)
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 28,
                      ),
                    ],
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
        final isActive = percentage >= segmentThreshold - 12;

        return Expanded(
          child: Container(
            height: 10,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
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
