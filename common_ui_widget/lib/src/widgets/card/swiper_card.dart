import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class Swipercard extends StatefulWidget {
  final String titoloSuperiore;
  final String titolo;
  final String descrizione;
  final double radius;
  final Color borderColor;
  final Color backGroundColor;
  final List<List> iconButton;
  final Color iconColor;
  final double radiusButton;
  final double imageWidth;
  final double imageHeight;
  final Path? image3DPath;
  final String? imagePath;
  final VoidCallback onTap;
  final TextStyle titoloSuperioreStyle;
  final TextStyle titoloStyle;
  final TextStyle descrizioneStyle;

  const Swipercard({
    super.key,
    required this.titoloSuperiore,
    required this.titolo,
    required this.descrizione,
    required this.radius,
    required this.borderColor,
    required this.backGroundColor,
    required this.iconButton,
    required this.iconColor,
    required this.imageWidth,
    required this.imageHeight,
    required this.radiusButton,
    required this.onTap,
    required this.titoloSuperioreStyle,
    required this.titoloStyle,
    required this.descrizioneStyle,
    this.image3DPath,
    this.imagePath,
  });

  @override
  State<Swipercard> createState() => _SwipercardState();
}

class _SwipercardState extends State<Swipercard> {
  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final surfaceShape = SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: widget.radius,
        cornerSmoothing: 0.8,
      ),
    );

    return Container(
      width: 340,
      height: 140,
      decoration: ShapeDecoration(
        gradient: colors.cardBorderGradient,
        shape: surfaceShape,
        shadows: colors.cardShadows,
      ),

      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: surfaceShape),
          child: Container(
            width: 340,
            height: 150,
            decoration: ShapeDecoration(
              shape: surfaceShape,
              gradient: colors.cardGradient,
            ),
            child: Stack(
              children: [
                // =========================================================
                // 1. GLOW SINISTRO
                // =========================================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.borderColor.withValues(alpha: 0.34),
                            widget.borderColor.withValues(alpha: 0.18),
                            widget.borderColor.withValues(alpha: 0.07),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.18, 0.40, 0.52],
                        ),
                      ),
                    ),
                  ),
                ),

                // =========================================================
                // 2. GLOW INFERIORE
                // =========================================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            widget.borderColor.withValues(alpha: 0.32),
                            widget.borderColor.withValues(alpha: 0.17),
                            widget.borderColor.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.20, 0.42, 0.62],
                        ),
                      ),
                    ),
                  ),
                ),

                // =========================================================
                // 3. HOTSPOT BOTTOM-LEFT
                // Fonde il glow sinistro con quello inferiore.
                // È questo che evita l'effetto "L fatta con due barre".
                // =========================================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.95, 0.95),
                          radius: 0.90,
                          colors: [
                            widget.borderColor.withValues(alpha: 0.30),
                            widget.borderColor.withValues(alpha: 0.15),
                            widget.borderColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.28, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // =========================================================
                // 4. LEGGERO SCURIMENTO TOP-RIGHT
                // Tiene quella zona pulita e quasi nera.
                // =========================================================

                // =========================================================
                // 5. GLOW "PAVIMENTO" SOTTO GARAGE
                // =========================================================
                Positioned(
                  right: -5,
                  bottom: 2,
                  child: IgnorePointer(
                    child: Container(
                      width: 155,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: widget.borderColor.withValues(alpha: 0.24),
                            blurRadius: 24,
                            spreadRadius: 9,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // =========================================================
                // 6. OMBRA DI CONTATTO
                // Molto più piccola del glow arancione.
                // Fa sembrare garage e chiave realmente appoggiati.
                // =========================================================

                // =========================================================
                // 7. COLONNA TESTI
                // =========================================================
                Positioned(
                  left: 20,
                  top: -6,
                  // AmSoftButton conserva un touch target di 44 px anche se
                  // la superficie visiva è 40 px: questi 4 px lo accomodano.
                  bottom: 6,
                  width: 185,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titoloSuperiore,
                        style: widget.titoloSuperioreStyle,
                      ),

                      const SizedBox(height: 4),

                      Text(widget.titolo, style: widget.titoloStyle),

                      const SizedBox(height: 4),

                      Text(
                        widget.descrizione,
                        style: widget.descrizioneStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      OCLiquidGlassGroup(
                        settings: OCLiquidGlassSettings(
                          refractStrength: 0,
                          blurRadiusPx: 0,
                          specStrength: 1,
                          specWidth: 1,
                          specAngle: 145,
                          specPower: 8,
                        ),
                        child: AmSoftButton(
                          width: 40,
                          height: 40,
                          icon: widget.iconButton,
                          iconWeight: 2.2,
                          iconSize: 22,
                          liquidGlassEnabled: true,
                          color: widget.borderColor,
                          colorOpacity: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // =========================================================
                // 8. IMMAGINE 3D
                // =========================================================
                if (widget.imagePath != null)
                  Positioned(
                    right: -10,
                    bottom: 0,
                    child: Transform.scale(
                      scale: 1.05,
                      alignment: Alignment.bottomRight,
                      child: Image.asset(
                        widget.imagePath!,
                        width: widget.imageWidth,
                        height: widget.imageHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
