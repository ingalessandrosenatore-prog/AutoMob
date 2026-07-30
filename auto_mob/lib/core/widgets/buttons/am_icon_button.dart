import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/haptic_service.dart';

/// Pulsante icona riutilizzabile, compatibile sia con HugeIcons sia con
/// i normali [IconData] di Flutter.
class AmIconButton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final bool showShadow;
  final Color shadowColor;
  final double shadowBlurRadius;
  final double shadowSpreadRadius;
  final Offset shadowOffset;
  final Color backgroundColor;
  final Color iconColor;
  final Object icon;
  final double iconSize;
  final double strokeWidth;
  final double iconTurns;
  final VoidCallback onPressed;
  final String? tooltip;

  const AmIconButton({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
    required this.showShadow,
    required this.shadowColor,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.onPressed,
    this.shadowBlurRadius = 10,
    this.shadowSpreadRadius = 0,
    this.shadowOffset = const Offset(0, 3),
    this.iconSize = 24,
    this.strokeWidth = 2,
    this.iconTurns = 0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: Colors.transparent),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: shadowBlurRadius,
                  spreadRadius: shadowSpreadRadius,
                  offset: shadowOffset,
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () {
            AmHaptics.tap();
            onPressed();
          },
          child: Center(
            child: Transform.rotate(
              angle: iconTurns * 2 * math.pi,
              child: _AmAdaptiveIcon(
                icon: icon,
                color: iconColor,
                size: iconSize,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );

    final sizedButton = SizedBox(width: width, height: height, child: button);
    return tooltip == null
        ? sizedButton
        : Tooltip(message: tooltip!, child: sizedButton);
  }
}

class _AmAdaptiveIcon extends StatelessWidget {
  final Object icon;
  final Color color;
  final double size;
  final double strokeWidth;

  const _AmAdaptiveIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (icon is List<List>) {
      return HugeIcon(
        icon: icon as List<List>,
        color: color,
        size: size,
        strokeWidth: strokeWidth,
      );
    }

    if (icon is IconData) {
      return Icon(icon as IconData, color: color, size: size);
    }

    throw ArgumentError.value(
      icon,
      'icon',
      'Deve essere un IconData o un dato icona HugeIcons.',
    );
  }
}
