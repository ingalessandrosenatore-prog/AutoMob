import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../domain/entities/subscription_overview.dart';

class MechanicCodeCard extends StatelessWidget {
  const MechanicCodeCard({super.key, required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final digits = code.padRight(6).substring(0, 6).split('');
    return _DashboardCard(
      key: const ValueKey('mechanic_code_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CardIcon(icon: Icons.key_rounded, color: colors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Codice officina',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Comunicalo ai clienti per collegare i loro veicoli',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OCLiquidGlassGroup(
                settings: const OCLiquidGlassSettings(
                  refractStrength: -0.08,
                  blurRadiusPx: 1,
                  specStrength: 0,
                  specWidth: 0,
                  specAngle: 145,
                  specPower: 10,
                  lightbandOffsetPx: 7,
                  lightbandStrength: 0.5,
                ),
                child: AmSoftButton(
                  key: const ValueKey('copy_mechanic_code_button'),
                  width: 44,
                  height: 44,
                  icon: Icons.content_copy_rounded,
                  iconSize: 20,
                  tooltip: 'Copia codice',
                  color: colors.background,
                  colorOpacity: 0.2,
                  iconColor: colors.textPrimary,
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Semantics(
            label: 'Codice officina $code',
            child: Row(
              key: ValueKey('mechanic_code_$code'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final digit in digits)
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        maxWidth: 52,
                      ),
                      height: 54,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        digit,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.overview,
    this.onPressed,
  });

  final SubscriptionOverview overview;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    if (!overview.hasPlan) {
      return _DashboardCard(
        key: const ValueKey('subscription_plan_card'),
        highlighted: true,
        onTap: onPressed,
        semanticLabel: 'Scopri i piani disponibili',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nessun piano attivo',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inizia gratis e disdici quando vuoi, senza vincoli.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Text(
                  'SCOPRI I PIANI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final status = switch (overview.status) {
      SubscriptionStatus.active => ('Attivo', colors.accent),
      SubscriptionStatus.expiring => ('In scadenza', colors.info),
      SubscriptionStatus.expired => ('Scaduto', colors.danger),
      SubscriptionStatus.inactive => ('Non attivo', colors.textSecondary),
    };
    return _DashboardCard(
      key: const ValueKey('subscription_plan_card'),
      highlighted: true,
      onTap: onPressed,
      semanticLabel: 'Apri abbonamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IL TUO PIANO',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      overview.planName,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: status.$1, color: status.$2),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _PlanDetail(
                  label: 'Scadenza',
                  value: overview.expiresAt == null
                      ? 'Non impostata'
                      : _formatDate(overview.expiresAt!),
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PlanDetail(
                  label: 'Tempo rimasto',
                  value: overview.expiresAt == null
                      ? '—'
                      : '${overview.daysRemaining} giorni',
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VehicleUsageCard extends StatelessWidget {
  const VehicleUsageCard({super.key, required this.overview});

  final SubscriptionOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final vehicleLimit = overview.vehicleLimit;
    final available = vehicleLimit == null
        ? null
        : (vehicleLimit - overview.linkedVehicles).clamp(0, vehicleLimit);
    return _DashboardCard(
      key: const ValueKey('vehicle_usage_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CardIcon(
                icon: Icons.directions_car_rounded,
                color: colors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veicoli collegati',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text.rich(
                key: ValueKey('linked_vehicles_${overview.linkedVehicles}'),
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${overview.linkedVehicles}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${vehicleLimit ?? '∞'}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              key: const ValueKey('vehicle_usage_progress'),
              value: overview.vehicleUsage,
              minHeight: 8,
              color: colors.accent,
              backgroundColor: colors.textSecondary.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            available == null
                ? 'Posti illimitati'
                : '$available posti ancora disponibili',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkshopSummaryCard extends StatelessWidget {
  const WorkshopSummaryCard({
    super.key,
    required this.workshopName,
    required this.onPressed,
  });

  final String workshopName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return _DashboardCard(
      key: const ValueKey('workshop_summary_card'),
      onTap: onPressed,
      semanticLabel: 'Apri profilo officina',
      child: Row(
        children: [
          _CardIcon(icon: Icons.storefront_rounded, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profilo officina',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  workshopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    super.key,
    required this.child,
    this.highlighted = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final bool highlighted;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final radius = BorderRadius.circular(24);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              gradient: highlighted
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.accent.withValues(alpha: 0.12),
                        colors.surface,
                        colors.surface,
                      ],
                      stops: const [0, 0.48, 1],
                    )
                  : null,
              borderRadius: radius,
              border: Border.all(
                color: highlighted
                    ? colors.accent.withValues(alpha: 0.22)
                    : colors.textPrimary.withValues(alpha: 0.06),
              ),
            ),
            child: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ),
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  const _CardIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 22),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PlanDetail extends StatelessWidget {
  const _PlanDetail({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: colors.textSecondary, fontSize: 10),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
