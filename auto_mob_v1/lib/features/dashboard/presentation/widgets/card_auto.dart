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
  final String targa;
  final String? immaginePath;
  final int anno;
  final DateTime? kmUpdatedAt;
  final int estimatedAdditionalKm;
  final int daysSinceKmUpdate;
  final DateTime? nextRevisionDate;
  final DateTime? referenceDate;

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
    required this.targa,
    required this.anno,
    this.immaginePath,
    this.kmUpdatedAt,
    this.estimatedAdditionalKm = 0,
    this.daysSinceKmUpdate = 0,
    this.nextRevisionDate,
    this.referenceDate,
    this.onKmTap,
    this.onRevisionTap,
    this.onEditPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final now = referenceDate ?? DateTime.now();

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
                          164.0,
                          232.0,
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
                  _VehicleInfoPanel(
                    marca: marca,
                    modello: modello,
                    kmTotali: kmTotali,
                    targa: targa,
                    anno: anno,
                    kmUpdatedAt: kmUpdatedAt,
                    estimatedAdditionalKm: estimatedAdditionalKm,
                    daysSinceKmUpdate: daysSinceKmUpdate,
                    nextRevisionDate: nextRevisionDate,
                    now: now,
                    onKmTap: onKmTap,
                    onRevisionTap: onRevisionTap,
                  ),
                ],
              ),
            ),
            /*
            Vecchia grafica conservata come riferimento: i due piccoli box
            Revisione/KM vivevano separati sotto la card principale.
            const SizedBox(height: 8),
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
                          _RevisionStatusPill(status: 'STATO REVISIONE'),
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
            */
          ],
        ),
      ),
    );
  }
}

/*
Vecchi widget grafici della card conservati intenzionalmente come riferimento.
Erano usati dal layout a due pulsanti rettangolari commentato sopra.
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

*/

class _VehicleInfoPanel extends StatelessWidget {
  const _VehicleInfoPanel({
    required this.marca,
    required this.modello,
    required this.kmTotali,
    required this.targa,
    required this.anno,
    required this.kmUpdatedAt,
    required this.estimatedAdditionalKm,
    required this.daysSinceKmUpdate,
    required this.nextRevisionDate,
    required this.now,
    required this.onKmTap,
    required this.onRevisionTap,
  });

  final String marca;
  final String modello;
  final String kmTotali;
  final String targa;
  final int anno;
  final DateTime? kmUpdatedAt;
  final int estimatedAdditionalKm;
  final int daysSinceKmUpdate;
  final DateTime? nextRevisionDate;
  final DateTime now;
  final VoidCallback? onKmTap;
  final VoidCallback? onRevisionTap;

  String get _updateLabel => switch (daysSinceKmUpdate) {
    0 => 'Aggiornati oggi',
    1 => 'Aggiornati ieri',
    final days => 'Aggiornati $days giorni fa',
  };

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${marca.trim()} ${modello.trim()}'.trim().toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (anno > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceDeep,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$anno',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _LicensePlate(plate: targa),
          const SizedBox(height: 8),
          _MileageSection(
            kmTotali: kmTotali,
            updateLabel: kmUpdatedAt == null
                ? 'Data aggiornamento non disponibile'
                : _updateLabel,
            estimatedAdditionalKm: estimatedAdditionalKm,
            onTap: onKmTap,
          ),
          const SizedBox(height: 12),
          _RevisionTile(date: nextRevisionDate, now: now, onTap: onRevisionTap),
        ],
      ),
    );
  }
}

class _LicensePlate extends StatelessWidget {
  const _LicensePlate({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      key: const Key('vehicle-license-plate'),
      height: 38,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            decoration: const BoxDecoration(
              color: Color(0xFF1456A0),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'I',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              plate.trim().isEmpty ? '—' : plate.toUpperCase(),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MileageSection extends StatelessWidget {
  const _MileageSection({
    required this.kmTotali,
    required this.updateLabel,
    required this.estimatedAdditionalKm,
    required this.onTap,
  });

  final String kmTotali;
  final String updateLabel;
  final int estimatedAdditionalKm;
  final VoidCallback? onTap;

  String get _formattedCurrentKm {
    final digits = kmTotali.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(digits);
    return value == null ? kmTotali : '${_formatNumber(value)} km';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _formattedCurrentKm,
                key: const Key('vehicle-current-km'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.icon(
              key: const Key('update-km-button'),
              onPressed: onTap,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                color: Colors.white,
                size: 19,
                strokeWidth: 2.2,
              ),
              label: const Text(
                'AGGIORNA',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onMedia,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: colors.accent,
                  size: 19,
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    updateLabel,
                    key: const Key('km-last-update-label'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stimati: ${_formatNumber(estimatedAdditionalKm)} km',
                    key: const Key('km-estimated-increment'),
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _RevisionVisualStatus { regular, expiring, expired, unavailable }

class _RevisionTile extends StatelessWidget {
  const _RevisionTile({
    required this.date,
    required this.now,
    required this.onTap,
  });

  final DateTime? date;
  final DateTime now;
  final VoidCallback? onTap;

  _RevisionVisualStatus get _status {
    final revisionDate = date;
    if (revisionDate == null) return _RevisionVisualStatus.unavailable;
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      revisionDate.year,
      revisionDate.month,
      revisionDate.day,
    );
    if (due.isBefore(today)) return _RevisionVisualStatus.expired;
    if (due.difference(today).inDays <= 30) {
      return _RevisionVisualStatus.expiring;
    }
    return _RevisionVisualStatus.regular;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final status = _status;
    final warning = status != _RevisionVisualStatus.regular;
    final statusColor = warning ? colors.danger : colors.accent;
    final (statusLabel, statusDetail) = switch (status) {
      _RevisionVisualStatus.regular => (
        'Regolare',
        ' · scade ${_formatDate(date!)}',
      ),
      _RevisionVisualStatus.expiring => (
        'In scadenza',
        ' · scade ${_formatDate(date!)}',
      ),
      _RevisionVisualStatus.expired => (
        'Scaduta',
        ' · il ${_formatDate(date!)}',
      ),
      _RevisionVisualStatus.unavailable => (
        'Da impostare',
        ' · scadenza non disponibile',
      ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('revision-info-tile'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 60,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.accent.withValues(alpha: 0.9)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 28,
                bottom: -25,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  color: colors.accent.withValues(alpha: 0.08),
                  size: 82,
                  strokeWidth: 2.2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    HugeIcon(
                      key: const Key('revision-status-icon'),
                      icon: HugeIcons.strokeRoundedCalendar01,
                      color: colors.accent,
                      size: 26,
                      strokeWidth: 2.2,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REVISIONE',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: statusDetail,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            key: const Key('revision-status-label'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: colors.accent,
                      size: 23,
                      strokeWidth: 2.3,
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
}

String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}

String _formatNumber(int value) {
  final digits = value.abs().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return value < 0 ? '-$formatted' : formatted;
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
