import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

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
    final radius = BorderRadius.circular(100);

    // Fallback pastello: giallo chiarissimo quasi trasparente
    final fallbackColor = Colors.yellow.shade100.withOpacity(0.1);

    return GestureDetector(
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
        child: OCLiquidGlass(
          height: widget.height,
          width: widget.width,
          borderRadius: 100,
          enabled: false,
          color: widget.color?.withOpacity(0.8) ?? Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. BASE
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: widget.color == null ? fallbackColor : Colors
                      .transparent,
                  // Rimossa l'ombra interna che si espandeva troppo
                ),
              ),

              // 2. IL FLASH "STILE APPLE" CENTRATO E CONTROLLATO
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: lightCtrl,
                    builder: (context, child) =>
                    CustomPaint(
                      painter: GlowPainter(intensity : lightCtrl.value, color: Colors.white,)
                    )
                    ),



                    ),
                  ),
              

              // 3. CONTENUTI
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
          ),
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