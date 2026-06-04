import 'package:flutter/material.dart';

class AmAnimatedNavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color activeColor;
  final VoidCallback? onTap;
  final bool initialIsClicked;
  // Se fornito, il bottone è controllato dall'esterno e non toggling da solo.
  final bool? isSelected;

  const AmAnimatedNavButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.activeColor = const Color(0xFF4A90E2),
    this.onTap,
    this.initialIsClicked = false,
    this.isSelected,
  });

  bool get _isClicked => isSelected ?? initialIsClicked;

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: qui NON c'è nessun OCLiquidGlassGroup.
    // La forma di vetro deve registrarsi nel gruppo condiviso della barra
    // (vedi ShellScaffold) per potersi fondere con la bolla mobile.
    // Mettere un gruppo qui isolerebbe la forma e impedirebbe la fusione.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 75 ,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(100)),
         // color: _isClicked ? Colors.white10 : Colors.transparent
        ),
        child:  Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isClicked ? activeIcon : icon,
              color: _isClicked ? activeColor : Colors.white,
              size: 30,
            ),
            Text(
              label,
              style: TextStyle(
                color: _isClicked ? activeColor : Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                shadows: [
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
