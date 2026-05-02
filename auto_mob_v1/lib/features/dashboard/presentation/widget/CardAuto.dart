import 'dart:io';

import 'package:flutter/material.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

class CardAuto extends StatelessWidget {
  final String marca;
  final String modello;
  final String kmTotali;
  final String? immaginePath;

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          // Sfondo scuro che si vedrà in trasparenza sotto la sfocatura
          color: const Color(0xFF1C1C1E),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          // Lo Stack come radice permette di sovrapporre elementi fuori dal blur
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- LIVELLO 1: SFONDO (FOTO CON BLUR IN BASSO) ---
              SoftEdgeBlur(
                edges: [
                  EdgeBlur(
                    type: EdgeType.bottomEdge,
                    size: 140, // Area di sfocatura
                    sigma: 50,
                    tintColor: Colors.black,// Intensità
                    controlPoints: [
                      ControlPoint(position: 0.2, type: ControlPointType.visible),
                      ControlPoint(position: 1.0, type: ControlPointType.transparent),
                    ],
                  ),
                ],
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    // Overlay per scurire leggermente l'immagine e far risaltare il testo
                    Container(color: Colors.black.withOpacity(0.2)),
                  ],
                ),
              ),

              // --- LIVELLO 2: PRIMO PIANO (TESTI NITIDI, FUORI DAL BLUR) ---
              Positioned(
                bottom: 10, // Distanza dal fondo della card
                left: 15,
                right: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      marca.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF4A90E2),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.2,
                      ),
                    ),
                    Text(
                      modello.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24, // Leggermente ingrandito per impatto
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    // Box KM Totali
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        // Sfondo semi-trasparente elegante sopra il blur
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 3,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "KM TOTALI",
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                kmTotali,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
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
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final path = immaginePath;
    if (path == null || path.isEmpty) return _buildPlaceholder();
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    }
    if (path.startsWith('lib/') || path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
    }
    return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF2C2C2E),
      child: const Center(child: Icon(Icons.directions_car, color: Color(0xFF48484A), size: 50)),
    );
  }
}