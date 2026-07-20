import 'dart:io';

import 'package:auto_mob_v1/core/config/performance_flags.dart';
import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/core/widgets/smart/smart_edge.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

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

  /// Tap sul box Revisione apre il pop-up di aggiornamento scadenza.
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
    final colors = AmThemeColors.of(context);

    // Bottone matita con menu "MODIFICA FOTO". Lo shader di rifrazione
    // (OCLiquidGlassGroup) campiona lo sfondo in coordinate schermo: mentre la
    // card scorre, lo sfondo rifratto trasla e il vetro SEMBRA scivolare. Lo
    // accendiamo solo sui top di gamma (kHeavyEffects), come il resto dell'app
    // (pattern SmartGlass); con flag off resta la pillola scura piatta, ferma.
    final Widget editPull = AmPullDownLG(
      brand: '',
      lable: '',
      onTap: () {},
      backgroundColor: colors.background,
      popupBackgroundColor: colors.background.withValues(alpha: 0.5),
      // larghezza = larghezza del MENU che si apre (non della matita, che si
      // dimensiona sul contenuto). A 60 la voce "MODIFICA FOTO" andava in
      // overflow (~32px): serve spazio per icona + padding + testo.
      larghezza: 230,
      buttonIcons: HugeIcons.strokeRoundedEdit01,
      buttonIconsSize: 18,
      iconColor: colors.textPrimary,
      textColor: colors.textPrimary,
      buttonLableStyle: const TextStyle(fontSize: 0),
      arrow: false,
      children: [
        ItemMorphPopUp(
          icon: HugeIcons.strokeRoundedAlbum02,
          text: "MODIFICA FOTO",
          onTap: onEditPhotoTap ?? () {},
          iconColor: colors.accent,
          iconSize: 22,
          textColor: colors.textPrimary,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(9),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto e dati formano una sola superficie: l'edge inferiore della
            // foto sfuma per 10px nel colore della card, senza stacco visivo.
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: (constraints.maxWidth * 0.5625).clamp(
                          180.0,
                          260.0,
                        ),
                        child: SmartEdge(
                          blur: kHeavyEffects,
                          fallbackTint: colors.surface,
                          opacity: 0.96,
                          edges: [
                            EdgeBlur(
                              type: EdgeType.bottomEdge,
                              size: 10,
                              tintColor: colors.surface,
                              sigma: 10,
                              controlPoints: [
                                ControlPoint(
                                  position: 0.2,
                                  type: ControlPointType.visible,
                                ),
                                ControlPoint(
                                  position: 1.0,
                                  type: ControlPointType.transparent,
                                ),
                              ],
                            ),
                          ],
                          child: SizedBox.expand(
                            child: _VehicleImage(immaginePath: immaginePath),
                          ),
                        ),
                      ),
                      Positioned(top: 12, right: 12, child: editPull),
                    ],
                  ),
                  _InfoTile(
                    marca: marca,
                    modello: modello,
                    kmTotali: kmTotali,
                    anno: anno,
                  ),
                ],
              ),
            ),
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
                      watermarkIcon: HugeIcons.strokeRoundedCalendar01,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 3,
                        children: [
                          Text(
                            "REVISIONE",
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _RevisionStatusPill(status: _revisionStatus),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: _TapTile(
                      onTap: onKmTap,
                      // Nessun equivalente convincente trovato in HugeIcons 1.1.7.
                      // Mantengo il riferimento Material per il KPI km finché non
                      // troviamo un'icona più aderente.
                      watermarkIcon: HugeIcons.strokeRoundedDashboardSpeed02,
                      watermarkColor: colors.info,
                      child: Column(
                        spacing: 3,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AGGIORNA KM',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const _RevisionStatusPill(
                            status: 'ULTIMA MODIFICA: ...',
                          ),
                        ],
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

/// Dati del veicolo integrati alla foto: brand e km, poi modello e anno.
class _InfoTile extends StatelessWidget {
  final String marca;
  final String modello;
  final String kmTotali;
  final int anno;

  const _InfoTile({
    required this.marca,
    required this.modello,
    required this.kmTotali,
    required this.anno,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  marca.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    kmTotali,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  modello.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
              if (anno > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '$anno',
                  style: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
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
  final List<List>? watermarkIcon;
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
    final colors = AmThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        /*gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [colors.surfaceHighlight, colors.surfaceDeep]
              : [colors.surfaceDeep, colors.surfaceHighlight],
        ),*/
        color: colors.surface,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.surface.withValues(alpha: 0.26),
                          (watermarkColor ?? colors.accent).withValues(
                            alpha: 0.72,
                          ),
                        ],
                      ).createShader(bounds);
                    },
                    child: HugeIcon(
                      icon: watermarkIcon!,
                      size: 90,
                      color: colors.textPrimary,
                      strokeWidth: 2.2,
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
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
    final colors = AmThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: colors.textPrimary,
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
      return const _VehiclePlaceholder();
    }
    // Decodifica alla risoluzione DI VISUALIZZAZIONE, non a quella del file:
    // la card e' larga ~90% schermo, decodificare a piena risoluzione sprecava
    // RAM/CPU sul main isolate (concausa dei freeze). cacheWidth taglia il
    // decode alla larghezza reale in pixel fisici.
    final int cacheWidth =
        (MediaQuery.sizeOf(context).width *
                0.9 *
                MediaQuery.devicePixelRatioOf(context))
            .round();

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => const _VehiclePlaceholder(),
      );
    }
    if (path.startsWith('lib/') || path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, cacheWidth: cacheWidth);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => const _VehiclePlaceholder(),
    );
  }
}

class _VehiclePlaceholder extends StatelessWidget {
  const _VehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      color: colors.surfaceRaised,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedCar05,
          color: colors.textSecondary.withValues(alpha: 0.3),
          size: 50,
          strokeWidth: 2.2,
        ),
      ),
    );
  }
}
