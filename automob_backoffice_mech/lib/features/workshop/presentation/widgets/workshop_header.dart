import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Header persistente della Home: saluto del meccanico e accesso alle
/// impostazioni. La navigazione resta una callback della composition root.
class WorkshopAppBar extends StatelessWidget {
  const WorkshopAppBar({
    super.key,
    required this.mechanicName,
    this.onSettingsPressed,
  });

  final String mechanicName;
  final VoidCallback? onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        Expanded(child: MechanicGreeting(name: mechanicName)),
        const SizedBox(width: 16),
        // The glass group is kept around the tappable surface so the visual
        // effect does not alter the 48x48 minimum touch target.
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
          child: OCLiquidGlass(
            borderRadius: 37,
            color: colors.surfaceRaised.withValues(alpha: 0.4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: InkWell(
                borderRadius: BorderRadius.circular(37),
                onTap: onSettingsPressed,
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSettings02,
                    color: colors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MechanicGreeting extends StatelessWidget {
  const MechanicGreeting({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colors.surfaceRaised,
          child: Icon(Icons.handyman_rounded, color: colors.accent, size: 25),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buon lavoro,',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WorkshopClientListHeading extends StatelessWidget {
  const WorkshopClientListHeading({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'I tuoi clienti',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$total totali',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
