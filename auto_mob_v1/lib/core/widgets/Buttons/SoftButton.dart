import 'package:flutter/material.dart';

class AmSoftButton extends StatelessWidget {
  final String label;
  final double? width;
  final double? height;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const AmSoftButton({
    super.key,
    required this.label,
    this.width,
    this.height,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // Colore al centro più trasparente (soft effect)
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: color.withOpacity(0.5), // Bordo leggermente meno intenso del contenuto
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
