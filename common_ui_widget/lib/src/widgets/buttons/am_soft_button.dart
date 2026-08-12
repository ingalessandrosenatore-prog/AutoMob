import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Pulsante icona circolare condiviso dalle app AutoMob.
///
/// Accetta sia le icone HugeIcons sia i normali [IconData] di Flutter, cosi'
/// le app mantengono lo stesso comportamento senza duplicare varianti locali.
class AmSoftButton extends StatelessWidget {
  const AmSoftButton({
    required this.width,
    required this.height,
    required this.icon,
    super.key,
    this.color,
    this.iconColor,
    this.iconSize = 26,
    this.iconTurns = 0,
    this.tooltip,
    this.onPressed,
    this.liquidGlassEnabled = true,
  });

  final double width;
  final double height;
  final Object icon;
  final Color? color;
  final Color? iconColor;
  final double iconSize;
  final double iconTurns;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool liquidGlassEnabled;

  @override
  Widget build(BuildContext context) {
    final radius = math.min(width, height) / 2;
    final button = OCLiquidGlass(
      enabled: liquidGlassEnabled,
      width: width,
      height: height,
      borderRadius: radius,
      color: color ?? Colors.transparent,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Center(
            child: Transform.rotate(
              angle: iconTurns * 2 * math.pi,
              child: _AdaptiveIcon(
                icon: icon,
                color: iconColor ?? Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _AdaptiveIcon extends StatelessWidget {
  const _AdaptiveIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final Object icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (icon is List<List>) {
      return HugeIcon(icon: icon as List<List>, color: color, size: size);
    }
    if (icon is IconData) {
      return Icon(icon as IconData, color: color, size: size);
    }
    throw ArgumentError.value(
      icon,
      'icon',
      'Deve essere IconData o HugeIcons.',
    );
  }
}
