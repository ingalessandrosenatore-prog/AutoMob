import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../effects/am_flat_glass.dart';
import '../effects/am_liquid_glass_motion_scope.dart';
import '../effects/am_liquid_glass_repaint_controller.dart';
import '../effects/am_route_blur_transition.dart';
import '../../theme/am_control_metrics.dart';

/// Pulsante icona circolare condiviso dalle app AutoMob.
///
/// Accetta sia le icone HugeIcons sia i normali [IconData] di Flutter, cosi'
/// le app mantengono lo stesso comportamento senza duplicare varianti locali.
class AmSoftButton extends StatefulWidget {
  const AmSoftButton({
    required this.width,
    required this.height,
    required this.icon,
    super.key,
    this.color,
    this.colorOpacity,
    this.iconColor,
    this.iconSize = 26,
    this.iconWeight = 2.4,
    this.iconTurns = 0,
    this.label,
    this.tooltip,
    this.onPressed,
    this.liquidGlassEnabled = true,
    this.liquidGlassRepaint,
    this.routeAnimation,
    this.iSgradient = false,
    this.gradient,
    this.shadow = false,
    this.boxShadow,
  });

  final double width;
  final double height;
  final Object icon;
  final Color? color;
  final double? colorOpacity;
  final Color? iconColor;
  final double iconSize;
  final double iconWeight;
  final double iconTurns;
  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool liquidGlassEnabled;
  final AmLiquidGlassRepaintController? liquidGlassRepaint;
  final Animation<double>? routeAnimation;
  final bool? iSgradient;
  final Gradient? gradient;
  final bool shadow;
  final BoxShadow? boxShadow;

  @override
  State<AmSoftButton> createState() => _AmSoftButtonState();
}

class _AmSoftButtonState extends State<AmSoftButton>
    with TickerProviderStateMixin {
  static const _pressedScale = 1.08;
  static final _bounceSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 200),
    bounce: 0.30,
  );
  static final _lightSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 200),
    bounce: 0,
  );

  late final AnimationController _bounceController;
  late final AnimationController _lightController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController.unbounded(vsync: this, value: 1);
    _lightController = AnimationController(vsync: this);
    _bounceController.addListener(_repaintLiquidGlass);
  }

  void _repaintLiquidGlass() =>
      widget.liquidGlassRepaint?.updateScale(_bounceController.value);

  @override
  void dispose() {
    _bounceController.removeListener(_repaintLiquidGlass);
    _bounceController.dispose();
    _lightController.dispose();
    super.dispose();
  }

  void _animatePress() {
    _bounceController.animateWith(
      SpringSimulation(
        _bounceSpring,
        _bounceController.value,
        _pressedScale,
        0,
      ),
    );
    _lightController.animateWith(
      SpringSimulation(_lightSpring, _lightController.value, 0.5, 0),
    );
  }

  void _animateRelease() {
    _bounceController.animateWith(
      SpringSimulation(_bounceSpring, _bounceController.value, 1, 0),
    );
    _lightController.animateWith(
      SpringSimulation(_lightSpring, _lightController.value, 0, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liquidGlassEnabled =
        widget.liquidGlassEnabled &&
        !AmLiquidGlassMotionScope.isMovingOf(context);
    final radius = math.min(widget.width, widget.height) / 2;
    final baseColor = widget.colorOpacity == null
        ? widget.color ?? Colors.transparent
        : (widget.color ?? Colors.transparent).withValues(
            alpha: widget.colorOpacity!,
          );
    final surface = liquidGlassEnabled
        ? OCLiquidGlass(
            enabled: true,
            width: widget.width,
            height: widget.height,
            borderRadius: radius,
            color: baseColor,
            shadow: widget.shadow ? widget.boxShadow : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _SoftButtonContent(
                icon: widget.icon,
                iconColor: widget.iconColor ?? Colors.white,
                iconSize: widget.iconSize,
                iconWeight: widget.iconWeight,
                iconTurns: widget.iconTurns,
                label: widget.label,
                lightAnimation: _lightController,
                gradient: widget.iSgradient == true ? widget.gradient : null,
              ),
            ),
          )
        : AmFlatGlass(
            width: widget.width,
            height: widget.height,
            borderRadius: radius,
            color: baseColor,
            edgeLighten: 0.78,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _SoftButtonContent(
                icon: widget.icon,
                iconColor: widget.iconColor ?? Colors.white,
                iconSize: widget.iconSize,
                iconWeight: widget.iconWeight,
                iconTurns: widget.iconTurns,
                label: widget.label,
                lightAnimation: _lightController,
                gradient: widget.iSgradient == true ? widget.gradient : null,
              ),
            ),
          );
    final visual = AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) =>
          Transform.scale(scale: _bounceController.value, child: child),
      child: surface,
    );

    final interactive = widget.onPressed == null
        ? visual
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onPressed!();
            },
            onTapDown: (_) => _animatePress(),
            onTapUp: (_) => _animateRelease(),
            onTapCancel: _animateRelease,
            child: visual,
          );
    final content = widget.tooltip == null
        ? interactive
        : Tooltip(message: widget.tooltip!, child: interactive);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AmControlMetrics.minimumTouchTarget,
        minHeight: AmControlMetrics.minimumTouchTarget,
      ),
      child: Center(
        child: AmRouteBlurTransition(
          animation: widget.routeAnimation,
          child: content,
        ),
      ),
    );
  }
}

class _SoftButtonContent extends StatelessWidget {
  const _SoftButtonContent({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.iconWeight,
    required this.iconTurns,
    required this.lightAnimation,
    this.label,
    this.gradient,
  });

  final Object icon;
  final Color iconColor;
  final double iconSize;
  final double iconWeight;
  final double iconTurns;
  final String? label;
  final Animation<double> lightAnimation;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      if (gradient != null)
        Positioned.fill(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: lightAnimation,
            builder: (context, child) => CustomPaint(
              painter: _SoftButtonGlowPainter(
                intensity: lightAnimation.value,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: iconTurns * 2 * math.pi,
            child: _AdaptiveIcon(
              icon: icon,
              color: iconColor,
              size: iconSize,
              weight: iconWeight,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              label!,
              style: TextStyle(
                color: iconColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

class _AdaptiveIcon extends StatelessWidget {
  const _AdaptiveIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.weight,
  });

  final Object icon;
  final Color color;
  final double size;
  final double weight;

  @override
  Widget build(BuildContext context) {
    if (icon is List<List>) {
      return HugeIcon(
        icon: icon as List<List>,
        color: color,
        size: size,
        strokeWidth: weight,
      );
    }
    if (icon is IconData) {
      return Icon(icon as IconData, color: color, size: size, weight: weight);
    }
    throw ArgumentError.value(
      icon,
      'icon',
      'Deve essere IconData o HugeIcons.',
    );
  }
}

class _SoftButtonGlowPainter extends CustomPainter {
  const _SoftButtonGlowPainter({required this.intensity, required this.color});

  final double intensity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0 || size.isEmpty) return;

    final rect = Offset.zero & size;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.7 * intensity),
          color.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SoftButtonGlowPainter oldDelegate) =>
      oldDelegate.intensity != intensity || oldDelegate.color != color;
}
