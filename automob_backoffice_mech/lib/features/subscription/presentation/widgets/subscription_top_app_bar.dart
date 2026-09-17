import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class SubscriptionTopAppBar extends StatelessWidget {
  const SubscriptionTopAppBar({super.key, required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servizi',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gestisci officina e abbonamento',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
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
            key: const ValueKey('subscription_refresh_button'),
            width: 48,
            height: 48,
            icon: Icons.refresh_rounded,
            tooltip: 'Aggiorna dati',
            color: colors.background,
            colorOpacity: 0.2,
            iconColor: colors.textPrimary,
            onPressed: onRefresh,
          ),
        ),
      ],
    );
  }
}
