
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Un badge flottante che indica il veicolo selezionato.
/// Estetica: Pillola blu con icona auto e freccia per dropdown,
/// ora animata con espansione e luce interna (BlendMode.overlay).
class AmPullDownLG extends StatefulWidget {
  final String brand;
  final String lable;
  final Color? color;
  final IconData buttonIcons;
  final double buttonIconsSize;
  final Color buttonIconColor;
  final TextStyle buttonLableStyle;
  final double larghezza;
  final List<ItemMorphPopUp>
  children; // Aggiunto per poter controllare il colore dall'esterno
  final VoidCallback onTap;
  final bool arrow;

  const AmPullDownLG({
    super.key,
    required this.brand,
    required this.lable,
    this.color, // Parametro opzionale
    required this.onTap,
    required this.children,
    this.larghezza = 250.0,
    required this.buttonIcons,
    required this.buttonIconsSize,
    required this.buttonIconColor,
    required this.buttonLableStyle,
    required this.arrow,
  });

  @override
  State<AmPullDownLG> createState() => _AmPullDownLGState();
}

class _AmPullDownLGState extends State<AmPullDownLG>
    with TickerProviderStateMixin {
  late final AnimationController bounceCtrl;
  late final AnimationController lightCtrl;
  late final AnimationController morpheCtrl;
  final GlobalKey _triggerKey = GlobalKey();

  // Stato per memorizzare le coordinate e dimensioni del trigger
  Offset _triggerPos = Offset.zero;
  Size _triggerSize = Size.zero;

  static final SpringDescription _springDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 400),
        bounce: 0.2,
      );

  static final SpringDescription _lightDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 180),
        bounce: 0,
      );

  @override
  void initState() {
    super.initState();
    bounceCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    lightCtrl = AnimationController(vsync: this, value: 0.0);
    morpheCtrl = AnimationController.unbounded(vsync: this, value: 0);
    morpheCtrl.addListener(_onMorphChange);
  }

  void _onMorphChange() {}
  @override
  void dispose() {
    bounceCtrl.dispose();
    lightCtrl.dispose();
    morpheCtrl.dispose();
    super.dispose();
  }

  void _onRelese() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);
    final mcS = SpringSimulation(_springDescription, morpheCtrl.value, 1, 0);
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
    morpheCtrl.animateWith(mcS);
    _apriPopup(context, morpheCtrl);
  }

  void _onCancel() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  void _onPress() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1.25, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0.5, 0);

    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  void _misuraTrigger(BuildContext context) {
    final box = _triggerKey.currentContext!.findRenderObject() as RenderBox;
    _triggerPos = box.localToGlobal(Offset.zero);
    _triggerSize = box.size;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      // Gestione precisa degli stati del tocco
      onTapDown: (_) {
        _onPress();
        _misuraTrigger(_triggerKey.currentContext!);
      },
      onTapUp: (_) => _onRelese(),
      onTapCancel: () => _onCancel(),

      // 1. ANIMAZIONE DI ESPANSIONE (Scale: 1.05 per ingrandire)
      child: AnimatedBuilder(
        animation: Listenable.merge([bounceCtrl, morpheCtrl]),
        builder: (BuildContext context, Widget? child) {
          final apertura = (1 - morpheCtrl.value).clamp(0.0, 1.0);
          final scala = bounceCtrl.value * apertura;

          return Transform.scale(
            scale: scala,
            child: OCLiquidGlass(
              enabled: true ,
              color:
                  widget.color?.withValues(alpha: 0.2) ??
                  const Color(0xFF232326).withValues(alpha: 0.2),
              borderRadius: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 2. LIVELLO BASE E OMBRA
                  // Positioned.fill si adatta dinamicamente alle dimensioni della Row sottostante

                  // 3. LIVELLO LUCE APPLE (Vibrancy)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: lightCtrl,
                        builder: (context, child) => CustomPaint(
                          painter: GlowPainter(
                            intensity: morpheCtrl.value <= 0
                                ? lightCtrl.value
                                : morpheCtrl.value,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. CONTENUTI (Icone e Testo) in primo piano
                  // Qui applichiamo il padding che prima era nel Container genitore
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                            widget.buttonIcons,
                            size: widget.buttonIconsSize,
                            color: widget.buttonIconColor,

                        ),
                        if (widget.arrow) ...[const SizedBox(width: 4)],
                        Flexible(
                          child: Text(
                            widget.lable.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: widget.buttonLableStyle,
                          ),
                        ),
                        if (widget.arrow) ...[
                          const SizedBox(width: 4),
                        ], // Un po' di margine prima della freccia per simmetria
                        if (widget.arrow) ...[
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: widget.buttonIconColor,
                            size: widget.buttonIconsSize,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _apriPopup(BuildContext context, AnimationController m) {
    final Rect r = Rect.fromLTWH(
      _triggerPos.dx,
      _triggerPos.dy,
      _triggerSize.width,
      _triggerSize.height,
    );
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'chiudi',
      barrierColor: Colors.transparent,
      // L'animazione di apertura/chiusura è gestita interamente da `m`
      // (spring controller): la transizione di default della route (200ms)
      // altrimenti si somma a quella, tenendo la barriera "opaque" a
      // intercettare i tap per altri ~200ms dopo che il popup è già
      // sparito visivamente, dando la sensazione di UI bloccata.
      transitionDuration: Duration.zero,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return MorphPopUp(
              rectButton: r,
              larghezza: widget.larghezza,
              ctrlm: m,
              children: widget.children,
            );
          },
    );
  }
}

class MorphPopUp extends StatefulWidget {
  final Rect rectButton;
  final List<ItemMorphPopUp> children;
  final double larghezza;
  final AnimationController ctrlm;
  const MorphPopUp({
    super.key,
    required this.rectButton,
    required this.children,
    required this.larghezza,
    required this.ctrlm,
  });

  @override
  State<MorphPopUp> createState() => _PopUpState();
}

class _PopUpState extends State<MorphPopUp>
    with SingleTickerProviderStateMixin {
  bool _closing = false;

  void _closePopUp() {
    if (_closing) return;
    _closing = true;
    // La molla di chiusura ha bounce 0: raggiunge lo 0 in modo *asintotico*,
    // senza mai attraversarlo. Un check `value <= 0` quindi non scatterebbe
    // MAI, la route resterebbe montata e la sua barriera full-screen (più le
    // voci invisibili) continuerebbe a intercettare i tap → pagina "freezata".
    // `whenComplete` invece scatta appena la molla si assesta entro tolleranza,
    // quando il popup è già visivamente sparito.
    widget.ctrlm
        .animateWith(
          SpringSimulation(_springDescription, widget.ctrlm.value, 0, 0),
        )
        .whenComplete(() {
          if (mounted) Navigator.of(context).pop();
        });
  }

  static final SpringDescription _springDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 400),
        bounce: 0, // niente rimbalzo in chiusura: raggiunge lo 0 senza
        // oscillare, così il popup si richiude senza "rimbalzino" residuo
      );

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    const altezzaRiga = 48.0;
    const margine = 8.0;

    final altezzaFinale = widget.children.length * altezzaRiga + 16;

    // Direzione dinamica: se non c'è spazio a sufficienza a destra del
    // bottone, il popup si apre verso sinistra (allineando il bordo destro
    // al bordo destro del bottone) invece di uscire dallo schermo.
    final screenWidth = MediaQuery.of(context).size.width;
    final apreVersoSinistra =
        widget.rectButton.left + widget.larghezza > screenWidth - margine;
    final double leftFinale;
    if (widget.larghezza + margine * 2 > screenWidth) {
      leftFinale = margine;
    } else {
      final maxLeft = screenWidth - widget.larghezza - margine;
      final leftNaturale = apreVersoSinistra
          ? widget.rectButton.right - widget.larghezza
          : widget.rectButton.left;
      leftFinale = leftNaturale.clamp(margine, maxLeft).toDouble();
    }

    final reactFine = Rect.fromLTWH(
      leftFinale,
      widget.rectButton.top,
      widget.larghezza,
      altezzaFinale,
    );
    final rectInizio = widget.rectButton;

    return AnimatedBuilder(
      animation: widget.ctrlm,
      builder: (BuildContext context, Widget? child) {
        final t = widget.ctrlm.value;
        var rect = Rect.lerp(rectInizio, reactFine, t)!;
        final opac = (t / 0.3).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePopUp,
                behavior: HitTestBehavior
                    .opaque, // cattura i tap anche se trasparente
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: rect.left,
              top: rect.top,
              height: rect.height,
              width: rect.width,
              child: Opacity(
                opacity: opac,
                child: OCLiquidGlassGroup(
                  settings: const OCLiquidGlassSettings(
                    blurRadiusPx: 10,
                    refractStrength: 0.15,
                    specStrength: 0,
                    specWidth: 0,
                  ),
                  child: OCLiquidGlass(
                    enabled: true,
                    borderRadius:
                        30, // Ridotto da 100 per adattarsi meglio alla forma rettangolare
                    color: const Color(0xFF232326).withValues(alpha: 0.7),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: widget.children.length,
                      itemBuilder: (context, index) {
                        // Applichiamo un'opacità basata sull'animazione per i figli
                        return Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: widget.children[index],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ItemMorphPopUp extends StatelessWidget {
  final IconData icon;
  final String text;
  final double? textSize;
  final FontWeight? textWeight;
  final double? iconSize;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;
  final FontWeight? iconsWheight;

  const ItemMorphPopUp({
    super.key,
    required this.icon,
    required this.text,
    this.textSize = 16.0,
    this.textWeight = FontWeight.w700,
    this.iconSize = 24.0,
    this.iconColor = const Color(0xFFF48A37), // arancione
    this.textColor = Colors.white,
    required this.onTap,
    this.iconsWheight = FontWeight.w900,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // riposo: invisibile, si fonde col pop-up
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        hoverColor: Colors.white.withValues(alpha: 0.08), // mouse sopra
        splashColor: Colors.white.withValues(alpha: 0.15), // ripple al tap
        highlightColor: Colors.white.withValues(
          alpha: 0.10,
        ), // pressione tenuta
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: iconColor,fontWeight:  iconsWheight,),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: textSize,
                    fontWeight: textWeight,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlowPainter extends CustomPainter {
  final double intensity;
  final Color color;

  GlowPainter({required this.intensity, required this.color});
  @override
  void paint(Canvas c, Size s) {
    if (intensity <= 0) return;
    final paint = Paint();
    paint.blendMode = BlendMode.plus;
    final centro = color.withValues(alpha: 0.50 * intensity);
    final meta = color.withValues(alpha: 0.40 * intensity);
    final bordi = color.withValues(alpha: 0.3 * intensity);
    List<Color> colors = [centro, meta, bordi];
    final rect = Offset.zero & s;

    // 2. Creiamo il gradiente radiale che si espande dal centro di questo rettangolo
    paint.shader = RadialGradient(colors: colors).createShader(rect);

    // 3. Disegniamo un rettangolo arrotondato (Pillola).
    // Usando s.height / 2 come raggio, i bordi laterali saranno perfettamente curvi.
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s.height / 2));

    c.drawRRect(rrect, paint);

    /* Nota: Se volessi un VERO ovale geometrico (un'ellisse, non una pillola con i lati dritti),
     ti basterebbe sostituire le righe 3 con:
     c.drawOval(rect, paint);
    */
  }

  @override
  bool shouldRepaint(GlowPainter old) => old.intensity != intensity;
}
