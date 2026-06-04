import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class AmSoftButton extends StatelessWidget {
  final String? label;
  final double? width;
  final double? height;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const AmSoftButton({
    super.key,
    this.label,
    this.width,
    this.height,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(100);

    return GestureDetector(
      onTap: onPressed,
      child: OCLiquidGlassGroup(
        settings: const OCLiquidGlassSettings(
              refractStrength: -0.110, // Stronger refraction
              blurRadiusPx: 1.0, // Add frosted glass blur
              specStrength:0,

              specWidth:0.0,
              specAngle: 145,


          ),
        child: OCLiquidGlass(
            height: height,
            width: width,
            borderRadius: 100,
            color:color.withOpacity(0.7),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,

                children: [
                  Icon(icon, color: Colors.white, size: 25, weight: 200,),
          if(label!.isEmpty)...[
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ]
                ],
              ),
            ),
          ),
      ),
    );

  }
}