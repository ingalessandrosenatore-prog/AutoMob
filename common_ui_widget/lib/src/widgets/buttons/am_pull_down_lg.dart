import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

import '../effects/am_liquid_glass_repaint_controller.dart';
import '../effects/am_route_blur_transition.dart';
import '../effects/am_static_frosted_surface.dart';
import '../../theme/am_control_metrics.dart';

const _morphPopupCornerSmoothing = 0.8;
const _morphPopupBorderRadius = AmControlMetrics.pullDownRadius;
const _popupCloseDuration = Duration(milliseconds: 200);
SmoothRectangleBorder _morphPopupShape({
  double radius = _morphPopupBorderRadius,
}) => SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius(
    cornerRadius: radius,
    cornerSmoothing: _morphPopupCornerSmoothing,
  ),
);

double _responsivePopupRadius({
  required double requestedRadius,
  required double width,
  required double height,
}) => requestedRadius.clamp(0.0, math.min(width, height) / 2).toDouble();

/// Un badge flottante che indica il veicolo selezionato.
/// Estetica: Pillola blu con icona auto e freccia per dropdown,
/// ora animata con espansione e luce interna (BlendMode.overlay).
class AmPullDownLG extends StatefulWidget {
  final String brand;
  final String lable;
  final Color backgroundColor;
  final Color popupBackgroundColor;
  final List<List> buttonIcons;
  final double buttonIconsSize;
  final Color iconColor;
  final Color textColor;
  final TextStyle buttonLableStyle;
  final double larghezza;
  final List<ItemMorphPopUp>
  children; // Aggiunto per poter controllare il colore dall'esterno
  final VoidCallback onTap;
  final bool arrow;
  final bool liquidGlassEnabled;
  final bool? popupLiquidGlassEnabled;
  final bool ownsLiquidGlassGroup;
  final bool transparentTrigger;
  final AmLiquidGlassRepaintController? liquidGlassRepaint;
  final Animation<double>? routeAnimation;
  final double popupBorderRadius;
  final double? popupHeight;
  final BoxShadow? buttonShadow;
  final BoxShadow? popupShadow;
  final double triggerHeight;
  final EdgeInsetsGeometry triggerPadding;
  final double rowHeight;
  final double itemGap;
  final bool circularTrigger;

  const AmPullDownLG({
    super.key,
    required this.brand,
    required this.lable,
    required this.backgroundColor,
    required this.popupBackgroundColor,
    required this.onTap,
    required this.children,
    this.larghezza = AmControlMetrics.pullDownWidth,
    required this.buttonIcons,
    required this.buttonIconsSize,
    required this.iconColor,
    required this.textColor,
    required this.buttonLableStyle,
    required this.arrow,
    this.liquidGlassEnabled = true,
    this.popupLiquidGlassEnabled,
    this.ownsLiquidGlassGroup = true,
    this.transparentTrigger = false,
    this.liquidGlassRepaint,
    this.routeAnimation,
    this.popupBorderRadius = _morphPopupBorderRadius,
    this.popupHeight,
    this.buttonShadow,
    this.popupShadow,
    this.triggerHeight = AmControlMetrics.pullDownTriggerHeight,
    this.triggerPadding = AmControlMetrics.pullDownPadding,
    this.rowHeight = AmControlMetrics.pullDownRowHeight,
    this.itemGap = AmControlMetrics.pullDownItemGap,
    this.circularTrigger = false,
  }) : assert(popupBorderRadius >= 0),
       assert(popupHeight == null || popupHeight > 0),
       assert(triggerHeight > 0),
       assert(rowHeight >= AmControlMetrics.minimumTouchTarget),
       assert(itemGap >= 0);

  @override
  State<AmPullDownLG> createState() => _AmPullDownLGState();
}

class _AmPullDownLGState extends State<AmPullDownLG>
    with TickerProviderStateMixin {
  late final AnimationController bounceCtrl;
  late final AnimationController transistionCtrl;
  late final AnimationController lightCtrl;
  late final AnimationController morpheCtrl;
  final GlobalKey _triggerKey = GlobalKey();

  // Stato per memorizzare le coordinate e dimensioni del trigger
  Offset _triggerPos = Offset.zero;
  Size _triggerSize = Size.zero;

  static final SpringDescription _pressDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 200),
        bounce: 0.30,
      );

  static final SpringDescription _lightDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 200),
        bounce: 0.0,
      );

  static final SpringDescription _morphDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 400),
        bounce: 0.2,
      );

  @override
  void initState() {
    super.initState();
    bounceCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    transistionCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    lightCtrl = AnimationController(vsync: this, value: 0.0);
    morpheCtrl = AnimationController.unbounded(vsync: this, value: 0);
    bounceCtrl.addListener(_repaintLiquidGlass);
    morpheCtrl.addListener(_onMorphChange);
  }

  void _repaintLiquidGlass() =>
      widget.liquidGlassRepaint?.updateScale(bounceCtrl.value);

  void _onMorphChange() => _repaintLiquidGlass();
  @override
  void dispose() {
    bounceCtrl.removeListener(_repaintLiquidGlass);
    morpheCtrl.removeListener(_onMorphChange);
    bounceCtrl.dispose();
    lightCtrl.dispose();
    morpheCtrl.dispose();
    transistionCtrl.dispose();
    super.dispose();
  }

  void _onRelese() {
    HapticFeedback.selectionClick();
    final bcS = SpringSimulation(_pressDescription, bounceCtrl.value, 1, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);
    final mcS = SpringSimulation(_morphDescription, morpheCtrl.value, 1, 0);
    bounceCtrl.animateWith(bcS).whenComplete(() {
      if (mounted) bounceCtrl.value = 1;
    });
    lightCtrl.animateWith(lcS);
    morpheCtrl.animateWith(mcS);
    _apriPopup(context, morpheCtrl);
  }

  void _onCancel() {
    final bcS = SpringSimulation(_pressDescription, bounceCtrl.value, 1, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  void _onPress() {
    final bcS = SpringSimulation(_pressDescription, bounceCtrl.value, 1.15, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0.5, 0);

    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  void _resetPressAnimation() {
    bounceCtrl
      ..stop()
      ..value = 1;
    lightCtrl
      ..stop()
      ..value = 0;
  }

  void _misuraTrigger(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()!
            as RenderBox;
    // Il dialog usa il root navigator: anche dentro WorkLog le coordinate
    // devono quindi essere relative al suo Overlay, non al Navigator annidato.
    _triggerPos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    _triggerSize = box.size;
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: lightCtrl,
              builder: (context, child) => CustomPaint(
                key: const Key('am-pull-down-button-press-light'),
                painter: GlowPainter(
                  intensity: lightCtrl.value,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: widget.circularTrigger
              ? EdgeInsets.zero
              : widget.triggerPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!widget.arrow)
                HugeIcon(
                  icon: widget.buttonIcons,
                  size: widget.buttonIconsSize,
                  color: widget.iconColor,
                  strokeWidth: 2.2,
                ),
              if (widget.arrow) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.lable.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.buttonLableStyle.copyWith(
                    color: widget.textColor,
                  ),
                ),
              ),
              if (widget.arrow) const SizedBox(width: 4),
              if (widget.arrow)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: widget.iconColor,
                  size: widget.buttonIconsSize,
                  strokeWidth: 2.2,
                ),
            ],
          ),
        ),
      ],
    );
    final sizedContent = SizedBox(
      width: widget.circularTrigger ? widget.triggerHeight : null,
      height: widget.triggerHeight,
      child: content,
    );
    final Widget surface = widget.transparentTrigger
        ? sizedContent
        : AmStaticFrostedSurface(
            surfaceKey: const Key('am-pull-down-trigger-static-surface'),
            blurKey: const Key('am-pull-down-trigger-backdrop-blur'),
            decorationKey: const Key('am-pull-down-trigger-decoration'),
            borderRadius: widget.triggerHeight / 2,
            showShadow: widget.buttonShadow == null,
            child: sizedContent,
          );
    final shadowedSurface =
        widget.buttonShadow == null || widget.transparentTrigger
        ? surface
        : DecoratedBox(
            key: const Key('am-pull-down-button-shadow'),
            decoration: ShapeDecoration(
              shape: widget.circularTrigger
                  ? const CircleBorder()
                  : const StadiumBorder(),
              shadows: [widget.buttonShadow!],
            ),
            child: surface,
          );
    final pressVisual = AnimatedBuilder(
      animation: bounceCtrl,
      builder: (context, wchild) => Transform.scale(
        key: const Key('am-pull-down-press-surface-scale'),
        scale: bounceCtrl.value,
        child: wchild,
      ),
      child: shadowedSurface,
    );

    final button = GestureDetector(
      key: _triggerKey,
      onTapDown: (_) {
        _misuraTrigger(_triggerKey.currentContext!);
        _onPress();
      },
      onTapUp: (_) => _onRelese(),
      onTapCancel: _onCancel,
      child: SizedBox(
        width: widget.circularTrigger
            ? AmControlMetrics.minimumTouchTarget
            : null,
        height: AmControlMetrics.minimumTouchTarget,
        child: Center(
          child: AnimatedBuilder(
            animation: morpheCtrl,
            child: pressVisual,
            builder: (context, child) {
              final apertura = (1 - morpheCtrl.value).clamp(0.0, 1.0);
              return Opacity(
                key: const Key('am-pull-down-morph-opacity'),
                opacity: apertura,
                child: Transform.scale(
                  key: const Key('am-pull-down-morph-scale'),
                  scale: apertura,
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
    return AmRouteBlurTransition(
      animation: widget.routeAnimation,
      child: button,
    );
  }

  Future<void> _apriPopup(BuildContext context, AnimationController m) async {
    final Rect r = Rect.fromLTWH(
      _triggerPos.dx,
      _triggerPos.dy,
      _triggerSize.width,
      _triggerSize.height,
    );
    final selectedAction = await showGeneralDialog<VoidCallback>(
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
              backgroundColor: widget.popupBackgroundColor,
              popupBorderRadius: widget.popupBorderRadius,
              popupHeight: widget.popupHeight,
              popupShadow: widget.popupShadow,
              rowHeight: widget.rowHeight,
              itemGap: widget.itemGap,
              liquidGlassEnabled:
                  widget.popupLiquidGlassEnabled ?? widget.liquidGlassEnabled,
              onClosing: _resetPressAnimation,
              children: widget.children,
            );
          },
    );
    selectedAction?.call();
  }
}

class MorphPopUp extends StatefulWidget {
  final Rect rectButton;
  final List<ItemMorphPopUp> children;
  final double larghezza;
  final AnimationController ctrlm;
  final Color backgroundColor;
  final bool liquidGlassEnabled;
  final VoidCallback onClosing;
  final double popupBorderRadius;
  final double? popupHeight;
  final BoxShadow? popupShadow;
  final double rowHeight;
  final double itemGap;
  const MorphPopUp({
    super.key,
    required this.rectButton,
    required this.children,
    required this.larghezza,
    required this.ctrlm,
    required this.backgroundColor,
    required this.onClosing,
    this.liquidGlassEnabled = true,
    this.popupBorderRadius = _morphPopupBorderRadius,
    this.popupHeight,
    this.popupShadow,
    this.rowHeight = AmControlMetrics.pullDownRowHeight,
    this.itemGap = AmControlMetrics.pullDownItemGap,
  }) : assert(popupBorderRadius >= 0),
       assert(popupHeight == null || popupHeight > 0);

  @override
  State<MorphPopUp> createState() => _PopUpState();
}

class _PopUpState extends State<MorphPopUp> {
  bool _closing = false;
  bool _closeFinished = false;
  VoidCallback? _selectedAction;

  void _finishClose() {
    if (_closeFinished) return;
    _closeFinished = true;
    widget.ctrlm
      ..stop(canceled: false)
      ..value = 0;
    if (mounted) Navigator.of(context).pop(_selectedAction);
  }

  void _closePopUp([VoidCallback? selectedAction]) {
    if (_closing) return;
    _closing = true;
    _selectedAction = selectedAction;
    widget.onClosing();
    // Una durata finita porta il controller esattamente a zero: la route e la
    // sua barriera vengono rimosse insieme all'ultimo frame visibile.
    widget.ctrlm
        .animateTo(
          0,
          duration: _popupCloseDuration,
          curve: Curves.easeInOutCubic,
        )
        .whenComplete(_finishClose);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    const margine = 8.0;

    final altezzaContenuto = widget.children.length * widget.rowHeight + 16;

    // Direzione dinamica: se non c'è spazio a sufficienza a destra del
    // bottone, il popup si apre verso sinistra (allineando il bordo destro
    // al bordo destro del bottone) invece di uscire dallo schermo.
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    // Un menu lungo resta interamente nella viewport: la ListView interna
    // diventa scrollabile anziché essere tagliata dal ClipRRect della route.
    final altezzaFinale = (widget.popupHeight ?? altezzaContenuto)
        .clamp(widget.rowHeight + 16, screenSize.height - margine * 2)
        .toDouble();
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

    final maxTop = screenSize.height - altezzaFinale - margine;
    final topFinale = widget.rectButton.top.clamp(margine, maxTop).toDouble();
    final reactFine = Rect.fromLTWH(
      leftFinale,
      topFinale,
      widget.larghezza,
      altezzaFinale,
    );
    final rectInizio = widget.rectButton;
    final popupBorderRadius = _responsivePopupRadius(
      requestedRadius: widget.popupBorderRadius,
      width: widget.larghezza,
      height: altezzaFinale,
    );

    return AnimatedBuilder(
      animation: widget.ctrlm,
      builder: (BuildContext context, Widget? child) {
        final t = widget.ctrlm.value;
        var rect = Rect.lerp(rectInizio, reactFine, t)!;
        final animatedBorderRadius = _responsivePopupRadius(
          requestedRadius: widget.popupBorderRadius,
          width: rect.width,
          height: rect.height,
        );
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
              // Il contenuto viene SEMPRE disposto alla dimensione FINALE
              // (larghezza x altezzaFinale) via OverflowBox, e l'espansione la
              // fa il ClipRRect che scopre progressivamente questa finestra.
              // Cosi' la Row della voce non viene mai stretta piu' del suo
              // contenuto durante l'apertura/chiusura -> niente RenderFlex
              // overflow transitorio (l'errore "overflowed by 32px").
              child: _PopupShadow(
                shadow: widget.popupShadow,
                borderRadius: animatedBorderRadius,
                child: ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: _morphPopupShape(radius: animatedBorderRadius),
                  ),
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: widget.larghezza,
                    maxWidth: widget.larghezza,
                    minHeight: altezzaFinale,
                    maxHeight: altezzaFinale,
                    child: _PopUpSurface(
                      borderRadius: popupBorderRadius,
                      showShadow: widget.popupShadow == null,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: widget.children.length,
                        itemBuilder: (context, index) {
                          final item = widget.children[index];
                          // L'azione torna alla route chiamante e parte solo
                          // dopo la rimozione completa del popup.
                          return SizedBox(
                            key: ValueKey('am-pull-down-popup-row-$index'),
                            height: widget.rowHeight,
                            child: item.copyWithOnTap(
                              () => _closePopUp(item.onTap),
                              itemGap: widget.itemGap,
                            ),
                          );
                        },
                      ),
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

class _PopupShadow extends StatelessWidget {
  const _PopupShadow({
    required this.shadow,
    required this.borderRadius,
    required this.child,
  });

  final BoxShadow? shadow;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) => shadow == null
      ? child
      : DecoratedBox(
          key: const Key('am-pull-down-popup-shadow'),
          decoration: ShapeDecoration(
            shape: _morphPopupShape(radius: borderRadius),
            shadows: [shadow!],
          ),
          child: child,
        );
}

/// Superficie statica del menu, condivisa con i dialog di stato.
class _PopUpSurface extends StatelessWidget {
  final double borderRadius;
  final bool showShadow;
  final Widget child;

  const _PopUpSurface({
    required this.borderRadius,
    required this.showShadow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => AmStaticFrostedSurface(
    surfaceKey: const Key('am-pull-down-popup-static-surface'),
    blurKey: const Key('am-pull-down-popup-backdrop-blur'),
    decorationKey: const Key('am-pull-down-popup-decoration'),
    borderRadius: borderRadius,
    showShadow: showShadow,
    child: SizedBox(key: const Key('am-pull-down-popup-surface'), child: child),
  );
}

class ItemMorphPopUp extends StatelessWidget {
  final List<List> icon;
  final String text;
  final double? textSize;
  final FontWeight? textWeight;
  final double? iconSize;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;
  final FontWeight? iconsWheight;
  final double itemGap;

  const ItemMorphPopUp({
    super.key,
    required this.icon,
    required this.text,
    this.textSize,
    this.textWeight,
    this.iconSize,
    this.iconColor,
    this.textColor,
    required this.onTap,
    this.iconsWheight,
    this.itemGap = AmControlMetrics.pullDownItemGap,
  });

  /// Copia identica con un [onTap] diverso: serve al pop-up per iniettare la
  /// chiusura della route prima di eseguire l'azione originale della voce.
  ItemMorphPopUp copyWithOnTap(VoidCallback onTap, {double? itemGap}) =>
      ItemMorphPopUp(
        icon: icon,
        text: text,
        textSize: textSize,
        textWeight: textWeight,
        iconSize: iconSize,
        iconColor: iconColor,
        textColor: textColor,
        iconsWheight: iconsWheight,
        itemGap: itemGap ?? this.itemGap,
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    // Default fallback values
    final effectiveTextSize = textSize ?? 16.0;
    final effectiveTextWeight = textWeight ?? FontWeight.w600;
    final effectiveIconSize = iconSize ?? AmControlMetrics.pullDownIconSize;
    final effectiveIconColor = iconColor ?? const Color(0xFFF48A37);
    final effectiveTextColor = textColor ?? Colors.white;
    // ignore: unused_local_variable
    final effectiveIconsWeight = iconsWheight ?? FontWeight.w900;

    return Material(
      color: Colors.transparent, // riposo: invisibile, si fonde col pop-up
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        hoverColor: Colors.white.withValues(alpha: 0.08), // mouse sopra
        splashColor: Colors.white.withValues(alpha: 0.15), // ripple al tap
        highlightColor: Colors.white.withValues(
          alpha: 0.10,
        ), // pressione tenuta
        child: Padding(
          key: const Key('am-pull-down-item-padding'),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                size: effectiveIconSize,
                color: effectiveIconColor,
                strokeWidth: 1.5,
              ),
              SizedBox(width: itemGap),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: effectiveTextSize,
                    fontWeight: effectiveTextWeight,
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
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.7 * intensity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, paint);
  }

  @override
  bool shouldRepaint(GlowPainter old) => old.intensity != intensity;
}
