import 'package:flutter/material.dart';

class AmAnimatedNavButton extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool initialIsClicked;
  // Se fornito, il bottone è controllato dall'esterno e non toggling da solo.
  final bool? isSelected;
  // Notifica al genitore (la barra) lo stato di pressione, così il pill esterno
  // può fare lo scale.
  final ValueChanged<bool>? onPressChanged;

  const AmAnimatedNavButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.activeColor = const Color(0xFF4A90E2),
    this.onTap,
    this.initialIsClicked = false,
    this.isSelected,
    this.onPressChanged,
  });

  @override
  State<AmAnimatedNavButton> createState() => _AmAnimatedNavButtonState();
}

class _AmAnimatedNavButtonState extends State<AmAnimatedNavButton> {
  bool get _isClicked => widget.isSelected ?? widget.initialIsClicked;
  bool _isPressed = false;

  static final BorderRadius _radius = BorderRadius.circular(100);

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: qui NON c'è nessun OCLiquidGlassGroup.
    // La forma di vetro deve registrarsi nel gruppo condiviso della barra
    // (vedi ShellScaffold) per potersi fondere con la bolla mobile.
    // Mettere un gruppo qui isolerebbe la forma e impedirebbe la fusione.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onPressChanged?.call(true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressChanged?.call(false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onPressChanged?.call(false);
      },
      child: Container(
        height: 75 ,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: _radius,
          // Flash "stile Apple": Overlay schiarisce il chiaro e scurisce lo
          // scuro, dando luce integrata nel vetro senza patine.
          backgroundBlendMode: BlendMode.overlay,
          color: _isPressed
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child:  Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isClicked ? widget.activeIcon : widget.icon,
              color: _isClicked ? widget.activeColor : Colors.white,
              size: 24,
            ),
            Text(
              widget.label,
              style: TextStyle(
                color: _isClicked ? widget.activeColor : Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                shadows: const [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
