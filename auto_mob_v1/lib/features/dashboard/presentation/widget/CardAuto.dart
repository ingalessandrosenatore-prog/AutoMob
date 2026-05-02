import 'package:flutter/material.dart';

/// Card del veicolo per la Dashboard.
/// Visualizza l'immagine del veicolo con un overlay scuro, 
/// marca, modello e i chilometri totali in un box dedicato.
class CardAuto extends StatelessWidget {
  final String marca;
  final String modello;
  final String kmTotali;
  final String? immaginePath; // Path locale o URL

  const CardAuto({
    super.key,
    required this.marca,
    required this.modello,
    required this.kmTotali,
    this.immaginePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 250,// Ridotta leggermente per renderla più rettangolare
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1C1C1E),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Immagine di sfondo
              Positioned.fill(
                child: _buildImage(),
              ),

              // 2. Overlay Gradiente Scuro (Patina)
              // Va dal trasparente in alto allo scuro in basso per la leggibilità
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.6),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Contenuto Testuale
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Marca (Scritta Blu)
                    Text(
                      marca.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Modello (Scritta Bianca Bold Italic)
                    Text(
                      modello.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Box KM Totali
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Linea Blu di accento
                          Container(
                            width: 3,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "KM TOTALI",
                                style: TextStyle(
                                  color: Color(0xFF636366),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                kmTotali,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Decide tra Image.asset, Image.network o placeholder
  /// in base al formato del path passato.
  Widget _buildImage() {
    final path = immaginePath;
    if (path == null || path.isEmpty) return _buildPlaceholder();

    final isUrl = path.startsWith('http://') || path.startsWith('https://');
    final image = isUrl
        ? Image.network(path, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder())
        : Image.asset(path, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder());
    return image;
  }

  /// Placeholder se l'immagine non è presente
  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2C2C2E),
      child: const Center(
        child: Icon(
          Icons.directions_car,
          color: Color(0xFF48484A),
          size: 60,
        ),
      ),
    );
  }
}
