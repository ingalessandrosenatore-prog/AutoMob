import 'package:flutter/material.dart';

import '../../../../core/theme/am_theme_colors.dart';
import 'mechanic_carousel_layout.dart';

/// Etichetta e tessera +, leggere e accessibili, sopra la scena condivisa.
class MechanicCarouselLabel extends StatelessWidget {
  const MechanicCarouselLabel({
    super.key,
    required this.place,
    required this.width,
    required this.name,
    required this.showName,
    required this.onTap,
    this.plusPulse,
  });
  final MechanicCarouselLayout place;
  final double width;
  final String? name;
  final bool showName;
  final VoidCallback onTap;
  final Animation<double>? plusPulse;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Positioned(
      left: width * (.5 + place.x) - 55,
      bottom: 50 + (1 - place.scale) * 65 + (name == null ? 70 : 0),
      width: 110,
      child: Opacity(
        opacity: place.opacity,
        child: IgnorePointer(
          ignoring: place.opacity < .1,
          child: Semantics(
            button: true,
            label: name ?? 'Aggiungi officina',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name == null)
                    AnimatedBuilder(
                      animation: plusPulse ?? kAlwaysDismissedAnimation,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -5 * (plusPulse?.value ?? 0)),
                        child: Transform.scale(
                          scale: 1 + .09 * (plusPulse?.value ?? 0),
                          child: child,
                        ),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: colors.accent,
                        size: 58 * place.scale,
                      ),
                    ),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: showName
                        ? Text(
                            name ?? 'Collega officina',
                            key: ValueKey(name ?? 'add'),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10 + 4 * place.scale,
                            ),
                          )
                        : const SizedBox(key: ValueKey('hidden'), height: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
