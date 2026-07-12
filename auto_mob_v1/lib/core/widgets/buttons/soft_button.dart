import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../config/performance_flags.dart';
import '../../services/haptic_service.dart';
import '../smart/am_flat_glass.dart';

class AmSoftButton extends StatefulWidget {
  final String? label;
  final double? width;
  final double? height;
  final Color? color;
  final IconData icon;
  final VoidCallback onPressed;

  const AmSoftButton({
    super.key,
    this.label,
    this.width,
    this.height,
    this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<AmSoftButton> createState() => _AmSoftButtonState();
}

class _AmSoftButtonState extends State<AmSoftButton> with TickerProviderStateMixin {

  late final AnimationController bounceCtrl;
  late final AnimationController lightCtrl;


  static final SpringDescription _springDescription = SpringDescription
      .withDurationAndBounce(
      duration: const Duration(milliseconds: 200),
      bounce: 0.30
  );


  static final SpringDescription _lightDescription = SpringDescription
      .withDurationAndBounce(
      duration: const Duration(milliseconds: 200),
      bounce: 0.0
  );

  @override
  void initState() {
    super.initState();
    bounceCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    lightCtrl = AnimationController(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    bounceCtrl.dispose();
    lightCtrl.dispose();
    super.dispose();
  }

  void _onRelese() {
    final   bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    final  lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }


  void _onCancel() {
    final   bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    final  lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }


  void _onPress() {

  final   bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1.15, 0);
  final  lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0.5, 0);
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }


  @override
  Widget build(BuildContext context) {
    final Color base = widget.color?.withValues(alpha: 0.8) ?? Colors.transparent;

    // Contenuto del pulsante (glow + icona/testo), condiviso dai due rendering.
    final Widget content = Stack(
      alignment: Alignment.center,
      children: [
        // IL FLASH "STILE APPLE" CENTRATO E CONTROLLATO
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: lightCtrl,
              builder: (context, child) => CustomPaint(
                painter: GlowPainter(
                  intensity: lightCtrl.value,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // CONTENUTI
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: 26,
              fontWeight: FontWeight.w900,
            ),
            if (widget.label != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ]
          ],
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        AmHaptics.tap();
        widget.onPressed();
      },
      onTapDown: (_) => _onPress(),
      onTapUp: (_) => _onRelese(),
      onTapCancel:() => _onCancel(),
      child: AnimatedBuilder(
        animation: bounceCtrl,
        builder: (context, child) =>
            Transform.scale(
              scale: bounceCtrl.value,
              child: child,
            ),
        // Top di gamma: vetro reale. Altrimenti versione piatta (gradiente
        // col colore che schiarisce verso i bordi + un filo di opacity).
        child: kHeavyEffects
            ? OCLiquidGlass(
                height: widget.height,
                width: widget.width,
                borderRadius: 100,
                enabled: true,
                color: base,
                child: content,
              )
            : AmFlatGlass(
                height: widget.height,
                width: widget.width,
                borderRadius: 100,
                color: base,
                opacity: 0.9,
                child: content,
              ),
      ),
    );
  }


}

class GlowPainter  extends CustomPainter{

  final double intensity;
  final Color color ;

   GlowPainter({required this.intensity, required this.color});
  @override
  void paint(Canvas c , Size s) {
   if( intensity <= 0) return;
   final paint = Paint();
   paint.blendMode = BlendMode.plus;
   final centro = color.withValues(alpha: 0.7*intensity);
   final bordi = color.withValues(alpha: 0);
   List<Color> colors = [centro, bordi];
   paint.shader = RadialGradient(colors: colors).createShader(Offset.zero & s);
   c.drawRect(Offset.zero & s, paint);
   
   }


  @override
   bool shouldRepaint (GlowPainter old) => old.intensity != intensity;


}