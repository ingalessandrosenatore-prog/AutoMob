import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

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
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 95,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isClicked ? Colors.white10 : Colors.transparent,
            borderRadius: BorderRadius.circular(120),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isClicked ? activeIcon : icon,
                color:  _isClicked ? const Color(0xFFFF6B00) : Colors.white ,
                size: 30,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color:_isClicked ? const Color(0xFFFF6B00) : Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
