import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A single glow travels behind the destinations instead of fading per item.
class AmNavigationGlow extends StatelessWidget {
  const AmNavigationGlow({
    super.key,
    required this.alignment,
    required this.color,
    required this.width,
    required this.height,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedAlign(
      alignment: alignment,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: color.withValues(alpha: 0.60),
              width: 1.5,
            ),
            gradient: RadialGradient(
              center: const Alignment(-1.05, 1.15),
              radius: 1.4,
              colors: [
                color.withValues(alpha: 0.09),
                color.withValues(alpha: 0.04),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pointer feedback does not compete with destination tap recognizers.
class AmNavigationPress extends StatefulWidget {
  const AmNavigationPress({super.key, required this.child});

  final Widget child;

  @override
  State<AmNavigationPress> createState() => _AmNavigationPressState();
}

class _AmNavigationPressState extends State<AmNavigationPress>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController.unbounded(vsync: this, value: 1);
  static final _spring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 300),
    bounce: 0.1,
  );

  void _animate(double target) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.animateWith(
      SpringSimulation(_spring, _controller.value, target, 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _animate(1.05),
    onPointerUp: (_) => _animate(1),
    onPointerCancel: (_) => _animate(1),
    child: ScaleTransition(scale: _controller, child: widget.child),
  );
}
