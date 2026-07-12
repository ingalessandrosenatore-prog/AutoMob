import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../../../core/widgets/Effects/pulsing_glow_border.dart';
import '../../../../core/widgets/buttons/am_pull_down_lg.dart';

/// Card del veicolo nel PageView della home.
/// Card solida con ombra (3D), niente blur in tempo reale → swipe fluido.
class CardAuto extends StatelessWidget {
  final String marca;
  final String modello;
  final String kmTotali;
  final String? immaginePath;
  final int anno;
  final DateTime? nextRevisionDate;

  /// Tap sul box KM → apre il pop-up di aggiornamento km.
  final VoidCallback? onKmTap;

  /// Tap sul box Revisione (azione futura).
  final VoidCallback? onRevisionTap;

  /// Voce "MODIFICA FOTO" del pull-down sulla matita -> apre il picker e
  /// salva la nuova foto del veicolo.
  final VoidCallback? onEditPhotoTap;

  const CardAuto({
    super.key,
    required this.marca,
    required this.modello,
    required this.kmTotali,
    required this.anno,
    this.immaginePath,
    this.nextRevisionDate,
    this.onKmTap,
    this.onRevisionTap,
    this.onEditPhotoTap,
  });

  String get _revisionStatus {
    if (nextRevisionDate == null) return "N.D.";
    return nextRevisionDate!.isBefore(DateTime.now()) ? "Scaduta" : "OK";
  }

  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width * 0.90;

    return Container(
      width: cardWidth,

      decoration: BoxDecoration(
        color: const Color(0xFF232326), // stesso base delle card KPI
        borderRadius: BorderRadius.circular(32),

      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Immagine veicolo
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: _VehicleImage(immaginePath: immaginePath),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: OCLiquidGlassGroup(
                    settings: const OCLiquidGlassSettings(
                      refractStrength: -0.130,
                      blurRadiusPx: 1.0,
                      specStrength: 0,
                      specWidth: 0.0,
                      specAngle: 145,
                      blendPx: 70,
                      specPower: 10,
                    ),
                    child: AmPullDownLG(
                      brand: '',
                      lable: '',
                      onTap: () {},
                      larghezza: 60,
                      buttonIcons: Icons.edit,
                      buttonIconsSize: 18,
                      buttonIconColor: Colors.white,
                      buttonLableStyle: const TextStyle(fontSize: 0),
                      arrow: false,
                      children: [
                        ItemMorphPopUp(
                          icon: Icons.photo_camera_outlined,
                          text: "MODIFICA FOTO",
                          onTap: onEditPhotoTap ?? () {},
                          iconColor: const Color(0xFFF48A37),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Box Nome / Anno (a tutta larghezza)
            _InfoTile(marca: marca, modello: modello, anno: anno),
            const SizedBox(height: 8),

            // Box Revisione + Km (stessa altezza, cliccabili)
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TapTile(
                      onTap: onRevisionTap,
                      watermarkIcon: Icons.calendar_today,
                      child:Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 3,
                        children: [
                          const Text("REVISIONE", style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),),
                           const SizedBox(width: 6,),
                          _RevisionStatusPill(status: _revisionStatus),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: PulsingGlowBorder(
                      color: Colors.blueGrey.withValues(alpha: 0.5),
                      borderRadius: 20,
                      child: _TapTile(
                        onTap: onKmTap,
                        watermarkIcon: Icons.speed_outlined,
                        child: Column(
                          spacing: 3,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              kmTotali,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const _RevisionStatusPill(status: "AGGIORNA"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element -- debito tecnico, vedi docs/TECH_DEBT.md
const TextStyle _kTileLabel = TextStyle(
  color: Color(0xFF8E8E93),
  fontSize: 11,
  fontWeight: FontWeight.w900,
  letterSpacing: 1.0,
);

/// Arancione accento dell'app (usato nella dashboard).
const Color _kAppOrange = Color(0xFFFF6B00);

/// Box info nome + anno (non cliccabile, stesso stile dei tile sotto).
class _InfoTile extends StatelessWidget {
  final String marca;
  final String modello;
  final int anno;

  const _InfoTile({
    required this.marca,
    required this.modello,
    required this.anno,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C30),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled_outlined,
            color: _kAppOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand (sopra)
                      Text(
                        marca.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Modello (sotto)
                      Text(
                        modello.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Anno (in fondo a destra)
                if (anno > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      "$anno",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile cliccabile con ombra (look "bottone 3D"). Usato per Revisione e Km.
class _TapTile extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final IconData? watermarkIcon;
  final Color? watermarkColor;

  const _TapTile({
    required this.child,
    this.onTap,
    this.watermarkIcon,
    // ignore: unused_element_parameter -- debito tecnico, vedi docs/TECH_DEBT.md
    this.watermarkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C2C2E),
            Color(0xFF1C1C1E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (watermarkIcon != null)
              Positioned(
                right: -20,
                bottom: -15,
                child: Transform.rotate(
                  angle: -0,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          (watermarkColor ?? _kAppOrange).withValues(alpha: 0.1)
                        ],
                      ).createShader(bounds);
                    },
                    child: Icon(
                      watermarkIcon,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Center(child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pillola di stato revisione (OK / Scaduta / N.D.).
class _RevisionStatusPill extends StatelessWidget {
  final String status;

  const _RevisionStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Immagine del veicolo: rete, asset o file locale, con placeholder.
class _VehicleImage extends StatelessWidget {
  final String? immaginePath;

  const _VehicleImage({this.immaginePath});

  @override
  Widget build(BuildContext context) {
    final path = immaginePath;
    if (path == null || path.isEmpty) {
      return Container(
        color: const Color(0xFF2C2C2E),
        child: const Center(
          child: Icon(Icons.directions_car, color: Colors.white10, size: 50),
        ),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    if (path.startsWith('lib/') || path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}
