import 'dart:ui';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

SmoothRectangleBorder _smallPrincipalShape(
  double radius, {
  BorderSide side = BorderSide.none,
}) => SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: 0.8),
  side: side,
);

/// Pulsante principale compatto con materiale colorato, blur e bordi luminosi.
class SmallPrincipal extends StatelessWidget {
  const SmallPrincipal({
    super.key,
    this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 46,
    this.borderRadius,
    this.blurRadius = 6,
    this.horizontalPadding = 18,
    this.iconSize = 20,
    this.iconGap = 8,
    this.textColor = Colors.white,
    this.iconColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.shadow,
    this.isLoading = false,
  }) : assert(height > 0),
       assert(width == null || width > 0),
       assert(borderRadius == null || borderRadius >= 0),
       assert(blurRadius >= 0),
       assert(horizontalPadding >= 0),
       assert(iconSize > 0),
       assert(iconGap >= 0),
       assert(label != null || icon != null);

  final String? label;
  final Color color;
  final VoidCallback? onPressed;
  final List<List>? icon;
  final double? width;
  final double height;
  final double? borderRadius;
  final double blurRadius;
  final double horizontalPadding;
  final double iconSize;
  final double iconGap;
  final Color textColor;
  final Color? iconColor;
  final double fontSize;
  final FontWeight fontWeight;
  final BoxShadow? shadow;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? height / 2;
    final hasLabel = label != null && label!.isNotEmpty;
    final iconOnly = icon != null && !hasLabel;
    final enabled = onPressed != null;
    final interactive = enabled && !isLoading;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(color, Colors.white, 0.30)!.withValues(alpha: 1),
        color.withValues(alpha: 0.96),
        color.withValues(alpha: 0.96),
        Color.lerp(color, Colors.white, 0.30)!.withValues(alpha: 1),
      ],
      stops: const [0, 0.05, 0.95, 1],
      tileMode: TileMode.mirror,
    );

    final button = DecoratedBox(
      key: const Key('small-principal-shadow'),
      decoration: ShapeDecoration(
        shape: _smallPrincipalShape(radius),
        shadows: shadow == null ? const [] : [shadow!],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: _smallPrincipalShape(radius)),
        child: BackdropFilter(
          key: const Key('small-principal-backdrop-blur'),
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: DecoratedBox(
            key: const Key('small-principal-gradient'),
            decoration: ShapeDecoration(
              gradient: gradient,
              shape: _smallPrincipalShape(radius),
            ),
            child: CustomPaint(
              key: const Key('small-principal-edge-treatment'),
              foregroundPainter: _SmallPrincipalBorderPainter(
                borderRadius: radius,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('small-principal-tap-target'),
                  customBorder: _smallPrincipalShape(radius),
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.white.withValues(alpha: 0.12);
                    }
                    if (states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.focused)) {
                      return Colors.white.withValues(alpha: 0.06);
                    }
                    return Colors.transparent;
                  }),
                  onTap: interactive
                      ? () {
                          HapticFeedback.selectionClick();
                          onPressed!();
                        }
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: iconOnly ? 0 : horizontalPadding,
                    ),
                    child: isLoading
                        ? Center(
                            child: SizedBox.square(
                              dimension: iconSize,
                              child: CircularProgressIndicator(
                                color: textColor,
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
                                  color: iconColor ?? textColor,
                                  size: iconSize,
                                  strokeWidth: 2.2,
                                ),
                                if (hasLabel) SizedBox(width: iconGap),
                              ],
                              if (hasLabel)
                                Flexible(
                                  child: Text(
                                    label!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: fontSize,
                                      fontWeight: fontWeight,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: SizedBox(
        width: width ?? (iconOnly ? height : null),
        height: height,
        child: button,
      ),
    );
  }
}

/// Il bordo superiore e quello inferiore hanno intensita diverse; i lati
/// sfumano per mantenere la profondita vista nei pulsanti di riferimento.
class _SmallPrincipalBorderPainter extends CustomPainter {
  const _SmallPrincipalBorderPainter({required this.borderRadius});

  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final radius = borderRadius.clamp(0, size.shortestSide / 2).toDouble();
    final rect = Offset.zero & size;
    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xB8FFFFFF), Colors.transparent],
        stops: [0, 0.5, 1],
      ).createShader(rect);
    final bottomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0x8FFFFFFF), Colors.transparent],
      ).createShader(rect);
    final top = Path()
      ..moveTo(0.75, radius)
      ..quadraticBezierTo(0.75, 0.75, radius, 0.75)
      ..lineTo(size.width - radius, 0.75)
      ..quadraticBezierTo(size.width - 0.75, 0.75, size.width - 0.75, radius);
    final bottom = Path()
      ..moveTo(size.width - 0.75, size.height - radius)
      ..quadraticBezierTo(
        size.width - 0.75,
        size.height - 0.75,
        size.width - radius,
        size.height - 0.75,
      )
      ..lineTo(radius, size.height - 0.75)
      ..quadraticBezierTo(0.75, size.height - 0.75, 0.75, size.height - radius);
    canvas
      ..drawPath(top, topPaint)
      ..drawPath(bottom, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant _SmallPrincipalBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
