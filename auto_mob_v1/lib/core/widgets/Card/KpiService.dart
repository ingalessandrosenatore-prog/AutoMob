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
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1), // Lievissima ombra colorata
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Contenuto Testuale (Spostato a Sinistra)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      const TextSpan(text: 'Rimasti: '),
                      TextSpan(text: '${formatKm(remainingKm)} KM'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prossimo: ${formatKm(nextServiceKm)} km ${lastServiceDate != null ? "· $lastServiceDate" : ""}',
                  style: const TextStyle(
                    color: Color(0xFF636366),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Cerchio Percentuale con Glow (Spostato a Destra)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none, // Evita che il glow venga tagliato
            children: [
              // Sfondo del cerchio (grigio scuro)
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7, // Leggermente più spesso
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              // Glow esterno e indicatore di progresso
              SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _ExternalGlowPainter(
                    percentage: percentage,
                    color: color,
                    strokeWidth: 7, // Leggermente più spesso
                  ),
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter personalizzato per gestire il glow solo verso l'esterno.
class _ExternalGlowPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  _ExternalGlowPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2);
    final sweepAngle = (percentage / 100) * 2 * 3.141592653589793;
    const startAngle = -3.141592653589793 / 2;

    // 1. Disegna il Glow Esterno
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Disegniamo il glow prima del progresso principale
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      glowPaint,
    );

    // 2. Disegna l'arco di progresso principale
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExternalGlowPainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}
