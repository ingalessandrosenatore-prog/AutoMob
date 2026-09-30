import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, required this.registrationProgress});

  final double registrationProgress;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final progress = registrationProgress.clamp(0.0, 1.0);
    final logoSize = 36 - (6 * progress);

    return SizedBox(
      height: 184 - (72 * progress),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, -12 * progress),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Benvenuto in',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Semantics(
                label: 'AutoMob',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Aut',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: logoSize,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SvgPicture.asset(
                          'lib/assets/icons/ruota.svg',
                          key: const Key('auth-brand-wheel'),
                          width: logoSize * 0.8,
                          height: logoSize * 0.8,
                        ),
                      ),
                      Text(
                        'Mob',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: logoSize,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Prenditi cura dei tuoi veicoli',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
