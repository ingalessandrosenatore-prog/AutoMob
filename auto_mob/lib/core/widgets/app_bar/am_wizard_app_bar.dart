import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../config/performance_flags.dart';

class AmWizardAppBar extends StatelessWidget {
  const AmWizardAppBar({
    required this.title,
    required this.onBackPressed,
    this.backButtonKey,
    super.key,
  });

  static const height = 69.0;

  final String title;
  final VoidCallback onBackPressed;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final routeAnimation = ModalRoute.of(context)?.animation;
    final button = SizedBox.square(
      key: backButtonKey,
      dimension: 48,
      child: Center(
        child: AmSoftButton(
          width: AmControlMetrics.circularButtonVisualSize,
          height: AmControlMetrics.circularButtonVisualSize,
          iconSize: AmControlMetrics.circularButtonIconSize,
          color: colors.background.withValues(alpha: 0.3),
          iconColor: colors.textPrimary,
          icon: HugeIcons.strokeRoundedArrowLeft01,
          tooltip: 'Indietro',
          onPressed: onBackPressed,
          routeAnimation: routeAnimation,
        ),
      ),
    );
    final backButton = kHeavyEffects
        ? OCLiquidGlassGroup(
            repaint: routeAnimation,
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.08,
              blurRadiusPx: 2,
              specStrength: 1,
              specWidth: 0.5,
              specAngle: 145,
              specPower: 10,
              lightbandOffsetPx: 7,
              lightbandStrength: 0.5,
            ),
            child: button,
          )
        : button;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                title,
                key: const Key('wizard-app-bar-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Align(alignment: Alignment.centerLeft, child: backButton),
          ],
        ),
      ),
    );
  }
}
