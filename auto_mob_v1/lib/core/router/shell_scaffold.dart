import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

/// Voce della barra di navigazione.
class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class ShellScaffold extends StatefulWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold>
    with TickerProviderStateMixin {
  late final AnimationController bounceCtrl;
  late final AnimationController lightCtrl;
  bool isSelect1 = true;
  bool isSelect2 = false;
  bool isSelect3 = false;

  final ValueNotifier<Offset?> _tapPositionNotifier = ValueNotifier<Offset?>(
    null,
  );

  static final SpringDescription _springDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 300),
        bounce: 0.1,
      );

  static final SpringDescription _lightDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 250),
        bounce: 0,
      );

  static const List<_NavItem> _items = [
    _NavItem(
      route: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'GARAGE',
    ),
    _NavItem(
      route: '/lavori',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
      label: 'LAVORI',
    ),
    _NavItem(
      route: '/servizi',
      icon: Icons.list_sharp,
      activeIcon: Icons.list,
      label: 'SERVIZI',
    ),
  ];

  @override
  void initState() {
    super.initState();
    bounceCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
    lightCtrl = AnimationController(vsync: this, value: 0.0);
  }

  @override
  void didChangeDependencies() {}

  @override
  void dispose() {
    bounceCtrl.dispose();
    lightCtrl.dispose();
    _tapPositionNotifier.dispose();

    super.dispose();
  }

  void _onRelese() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);

    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  void _onCancel() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0, 0);

    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  void _onPress() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1.05, 0);
    final lcS = SpringSimulation(_lightDescription, lightCtrl.value, 0.5, 0);
    isSelect1 = false;
    isSelect3 = false;
    isSelect2 = false;
    bounceCtrl.animateWith(bcS);
    lightCtrl.animateWith(lcS);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    var selected = _items.indexWhere((it) => location.startsWith(it.route));
    if (selected == -1) selected = 0;




    final larghezzaSchermo = MediaQuery.sizeOf(context).width;
    final margine = (larghezzaSchermo * 15) / 100;
    const maxLarghezza = 500.0;
    final larghezzaBarra = math.min(
      larghezzaSchermo - 2 * margine,
      maxLarghezza,
    );

    void goTo(int index) {
      if (index < 0 || index >= _items.length) return;
      context.go(_items[index].route);
    }

    return Scaffold(
      // backgroundColor: const Color(0xFF1A1C23),
      body: Stack(
        children: [
          RepaintBoundary(child: widget.child),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,

            child:GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (event) {
                  _onPress();
                  _tapPositionNotifier.value = event.localPosition;
                },
                onPanUpdate: (event) {
                  _tapPositionNotifier.value = event.localPosition;
                },
                onPanEnd: (event) {
                  final dito = _tapPositionNotifier.value;
                  if (dito != null) {
                    // Il pan si conclude su un item: naviga davvero.
                    final itemWidth = larghezzaBarra / 3;
                    // localPosition è relativa al GestureDetector (tutto
                    // lo schermo in larghezza): riportala dentro la barra.
                    final inBar =
                        dito.dx - (larghezzaSchermo - larghezzaBarra) / 2;
                    final indice =
                    (inBar / itemWidth).floor().clamp(0, _items.length - 1);
                    goTo(indice);
                  }
                  _onRelese();
                },
                onPanCancel: () {
                  _onRelese();
                  _tapPositionNotifier.value = null;
                },
              child: Center(
                child: AnimatedBuilder(

                  animation: bounceCtrl,
                  builder: (context, child) =>
                      Transform.scale(
                    scale: bounceCtrl.value,
                    child: child,
                  ),


                  child: OCLiquidGlassGroup(
                    settings: const OCLiquidGlassSettings(
                      blurRadiusPx: 0,
                      specWidth: 0,
                      specStrength: 0,
                      refractStrength: 0.04
                    ),
                    child: OCLiquidGlass(
                      width: larghezzaBarra,
                      height: 58,
                      borderRadius: 100,
                      color: const Color(0x00595050),

                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: lightCtrl,
                                builder: (context, child) => CustomPaint(
                                  painter: GlowPainter(
                                    intensity: lightCtrl.value,
                                    color: Colors.white,
                                    tapPosition: _tapPositionNotifier.value,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Row(
                            children: List.generate(_items.length, (i) {
                              final item = _items[i];
                              return AmNavItem(
                                icon: item.icon,
                                iconIsActive: item.activeIcon,
                                iconColor: Colors.white,
                                iconSize: 26,
                                iconColoractive: const Color(0xFF3192F3),
                                lable: item.label,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                textColor: Colors.white,
                                textColorIsActive: const Color(0xFF3192F3),
                                background: Colors.transparent,
                                backgorundIsActive:
                                const Color(0xFF3192F3).withValues(alpha: 0.3),
                                onTap: () => goTo(i),
                                isSelect: selected == i,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AmNavItem extends StatefulWidget {
  final IconData icon;
  final IconData iconIsActive;
  final Color iconColor;
  final double iconSize;
  final Color iconColoractive;
  final String lable;
  final FontWeight fontWeight;
  final double fontSize;
  final Color textColor;
  final Color textColorIsActive;
  final Color background;
  final Color backgorundIsActive;
  final GestureTapCallback? onTap;
  final bool isSelect;

  const AmNavItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.iconColoractive,
    required this.lable,
    required this.fontWeight,
    required this.textColor,
    required this.textColorIsActive,
    required this.background,
    required this.backgorundIsActive,
    required this.fontSize,
    required this.onTap,
    required this.isSelect,
    required this.iconIsActive,
  });

  @override
  State<AmNavItem> createState() => _AmNavItemState();
}

class _AmNavItemState extends State<AmNavItem> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: widget.isSelect
                ? widget.backgorundIsActive
                : widget.background,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSelect ? widget.iconIsActive : widget.icon,
                size: widget.iconSize,
                color: widget.isSelect
                    ? widget.iconColoractive
                    : widget.iconColor,
              ),
              Text(
                widget.lable,
                style: TextStyle(
                  fontWeight: widget.fontWeight,
                  fontSize: widget.fontSize,
                  color: widget.isSelect
                      ? widget.textColorIsActive
                      : widget.textColor,
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
  final Offset? tapPosition; // <-- Nuova variabile

  GlowPainter({required this.intensity, required this.color, this.tapPosition});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );

    // Base del vetro
    final basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.15 * intensity);
    canvas.drawRRect(rrect, basePaint);

    // --- CALCOLO POSIZIONE LUCE ---

    // ------------------------------

    // Il Fascio di Luce dinamico
    final highlightPaint = Paint()..blendMode = BlendMode.plus;
    highlightPaint.shader = RadialGradient(
      // <-- Usiamo l'allineamento calcolato!
      radius: 1.3,
      colors: [
        color.withValues(alpha: 0.85 * intensity),
        color.withValues(alpha: 0.25 * intensity),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawRRect(rrect, highlightPaint);

    // Riflesso (rimane fermo per dare l'illusione della curvatura fissa del vetro)
    final reflectionPaint = Paint()..blendMode = BlendMode.screen;
    reflectionPaint.shader = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.3 * intensity),
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.05 * intensity),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);

    canvas.drawRRect(rrect, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant GlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.color != color ||
        oldDelegate.tapPosition != tapPosition; // Ridisegna se il tocco cambia
  }
}
