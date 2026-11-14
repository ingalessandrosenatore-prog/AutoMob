import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

const _mainFabSmoothing = 0.8;

SmoothRectangleBorder _mainFabShape(
  double height, {
  BorderSide side = BorderSide.none,
}) => SmoothRectangleBorder(
  side: side,
  borderRadius: SmoothBorderRadius(
    cornerRadius: height / 2,
    cornerSmoothing: _mainFabSmoothing,
  ),
);

/// Il pulsante principale (Main FAB) dell'applicazione.
/// Design a "pillola" con colore pieno, icona, testo e ombra luminescente (glow).
class AmMainFab extends StatelessWidget {
  final String label;
  final Color color;
  final List<List>? icon;
  final List<List>? trailingIcon;
  final double iconSize;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;

  const AmMainFab({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.trailingIcon,
    this.iconSize = 20,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    required this.height,
    this.fontSize = 18,
    this.fontWeight = FontWeight.bold,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final shape = _mainFabShape(
      height,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22), width: 0.8),
    );
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: color,
        shape: shape,
        shadows: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: color,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed();
                },
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: isLoading
                ? const Center(
                    widthFactor: 1,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        HugeIcon(
                          icon: icon!,
                          color: Colors.white,
                          size: iconSize,
                          strokeWidth: 2.2,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: fontWeight,
                          fontSize: fontSize,
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 6),
                        HugeIcon(
                          icon: trailingIcon!,
                          color: Colors.white,
                          size: iconSize,
                          strokeWidth: 2.2,
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
