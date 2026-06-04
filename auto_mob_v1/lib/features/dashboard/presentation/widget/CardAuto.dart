import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

class CardAuto extends StatelessWidget {
  final String marca;
  final String modello;
  final String kmTotali;
  final String? immaginePath;
  final int anno;
  final DateTime? nextRevisionDate;

  const CardAuto({
    super.key,
    required this.marca,
    required this.modello,
    required this.kmTotali,
    required this.anno,
    this.immaginePath,
    this.nextRevisionDate,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double cardWidth = mediaQuery.size.width * 0.90;

    return Center(
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. LIVELLO BASE: IL GLOW (Immagine sfocata dietro)
            Positioned(
              top: -35,
              bottom: -35,
              left: -25,
              right: -25,
              child: Opacity(
                opacity: 0.7, // Opacità abbassata come richiesto
                child: ShaderMask(
                  // La maschera radiale nasconde i bordi netti dell'immagine rendendoli trasparenti
                  shaderCallback: (Rect bounds) {
                    return const RadialGradient(
                      center: Alignment.center,
                      radius: 0.65,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.3, 1.0], // Svanisce dolcemente verso l'esterno
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 45.0, sigmaY: 45.0),
                    child: _buildImage(context),
                  ),
                ),
              ),
            ),

            // 2. LIVELLO INTERMEDIO: IL VETRO (Glassmorphism)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: const Color(0xFF1C1C1E).withOpacity(0.3),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Immagine veicolo Top
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: AspectRatio(
                                aspectRatio: 1.6, // Leggermente più basso per evitare overflow
                                child: _buildImage(context),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Info Veicolo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$marca $modello",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20, // Leggermente ridotto
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "$anno",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 14, // Leggermente ridotto
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "$kmTotali",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20, // Leggermente ridotto
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bottom KPI cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.6), size: 18),
                                    const SizedBox(height: 8),
                                    const Text("Revisione", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    _buildStatusPill(_getRevisionStatus()),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildKpiCard(
                                child: Column(
                                  children: [
                                    Text("CHILOMETRI", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                    const SizedBox(height: 4),
                                    Text(
                                      kmTotali.replaceAll(RegExp(r'[^0-9]'), ''),
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 2),
                                    Text("km totali", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _getDisplayValue() {
    // Simuliamo un valore basato sui km o altro, per estetica come l'immagine
    return "$kmTotali".split(' ')[0];
  }

  String _getRevisionStatus() {
    if (nextRevisionDate == null) return "N.D.";
    final now = DateTime.now();
    if (nextRevisionDate!.isBefore(now)) return "Scad.";
    return "OK";
  }

  Widget _buildStatusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12), // Ridotto da 16
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildImage(BuildContext context) {
    if (immaginePath == null || immaginePath!.isEmpty) {
      return Container(
        color: const Color(0xFF2C2C2E),
        child: const Center(child: Icon(Icons.directions_car, color: Colors.white10, size: 50)),
      );
    }
    if (immaginePath!.startsWith('http')) {
      return Image.network(immaginePath!, fit: BoxFit.cover);
    }
    if (immaginePath!.startsWith('lib/') || immaginePath!.startsWith('assets/')) {
      return Image.asset(immaginePath!, fit: BoxFit.cover);
    }
    return Image.file(File(immaginePath!), fit: BoxFit.cover);
  }
}