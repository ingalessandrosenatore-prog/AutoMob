import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/mechanic_summary.dart';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

const _workshopCardSmoothing = 0.8;

SmoothRectangleBorder _workshopShape({double radius = 22}) =>
    SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: _workshopCardSmoothing,
      ),
    );

/// Card dell'officina collegata al veicolo attualmente selezionato.
class AmWorkshopCard extends StatelessWidget {
  final MechanicSummary? mechanic;
  final VoidCallback? onTap;

  const AmWorkshopCard({super.key, required this.mechanic, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final currentMechanic = mechanic;
    final connected = currentMechanic != null;
    final accent = connected ? colors.info : colors.danger;

    return Semantics(
      button: onTap != null,
      label: connected
          ? 'Dettagli meccanico ${currentMechanic.businessName}'
          : 'Nessun meccanico collegato',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: _workshopShape(),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: colors.surface,
              shape: _workshopShape().copyWith(
                side: BorderSide(color: colors.border),
              ),
              shadows: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.09),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ShapeDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: _workshopShape(radius: 14),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWrench01,
                    color: accent,
                    size: 24,
                    strokeWidth: 2.2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Il tuo meccanico',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentMechanic?.businessName ??
                            'Nessun meccanico collegato',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
