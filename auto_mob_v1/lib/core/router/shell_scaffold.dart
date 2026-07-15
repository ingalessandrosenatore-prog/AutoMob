import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../config/performance_flags.dart';
import '../theme/am_theme_colors.dart';

class _NavItem {
  final String route;
  final List<List> icon;
  final List<List> activeIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class ShellScaffold extends StatefulWidget {
  /// Shell delle tab (indexedStack): tiene i 3 sottoalberi vivi e sa quale e'
  /// attivo. Sostituisce il vecchio `child` di ShellRoute.
  final StatefulNavigationShell navigationShell;
  const ShellScaffold({super.key, required this.navigationShell});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold>
    with TickerProviderStateMixin {
  late final AnimationController bounceCtrl;
  final ValueNotifier<Offset?> _tapPositionNotifier = ValueNotifier<Offset?>(
    null,
  );

  static final SpringDescription _springDescription =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 300),
        bounce: 0.1,
      );

  static const List<_NavItem> _items = [
    _NavItem(
      route: '/home',
      icon: HugeIcons.strokeRoundedGarage,
      activeIcon: HugeIcons.strokeRoundedGarage,
      label: 'Garage',
    ),
    _NavItem(
      route: '/lavori',
      icon: HugeIcons.strokeRoundedTransactionHistory,
      activeIcon: HugeIcons.strokeRoundedTransactionHistory,
      label: 'Lavori',
    ),

  ];

  @override
  void initState() {
    super.initState();
    bounceCtrl = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    bounceCtrl.dispose();
    _tapPositionNotifier.dispose();
    super.dispose();
  }

  void _onPress() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1.05, 0);
    bounceCtrl.animateWith(bcS);
  }

  void _onRelese() {
    final bcS = SpringSimulation(_springDescription, bounceCtrl.value, 1, 0);
    bounceCtrl.animateWith(bcS);
  }

  @override
  Widget build(BuildContext context) {
    // L'indice attivo lo dice direttamente la shell (non piu' il path).
    final selected = widget.navigationShell.currentIndex;
    final colors = AmThemeColors.of(context);

    const iconSize = 22.0;
    const selectedHorizontalPadding = 16.0;
    const unselectedHorizontalPadding = 12.0;
    const labelGap = 8.0;
    const itemGap = 8.0;
    const barHorizontalPadding = 3.0;
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14.5,
      letterSpacing: 0.3,
    );

    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final maxSelectedItemWidth = _items.fold<double>(0, (maxWidth, item) {
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: labelStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final itemWidth =
          iconSize + labelGap + painter.width + selectedHorizontalPadding * 2;
      return math.max(maxWidth, itemWidth);
    });
    const unselectedItemWidth = iconSize + unselectedHorizontalPadding * 2;
    final gapsWidth = math.max(0, _items.length - 1) * itemGap;

    // Riserva lo spazio per un solo elemento aperto e per gli altri compatti:
    // la pillola dipende dal numero di tab, ma non cambia larghezza al tap.
    final preferredBarWidth =
        barHorizontalPadding * 2 +
        maxSelectedItemWidth +
        unselectedItemWidth * math.max(0, _items.length - 1) +
        gapsWidth;
    final larghezzaBarra = math.min(
      preferredBarWidth,
      MediaQuery.sizeOf(context).width - 32,
    );

    void goTo(int index) {
      if (index < 0 || index >= _items.length) return;
      // initialLocation: true quando si ri-tocca la tab gia' attiva -> torna
      // alla radice del branch (comportamento standard delle bottom bar).
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(child: widget.navigationShell),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: bounceCtrl,
                builder: (context, child) =>
                    Transform.scale(scale: bounceCtrl.value, child: child),
                // Usiamo Listener per l'animazione di rimbalzo globale
                // senza interferire o sballare i calcoli dei tap sui singoli pulsanti
                child: Listener(
                  onPointerDown: (_) => _onPress(),
                  onPointerUp: (_) => _onRelese(),
                  onPointerCancel: (_) => _onRelese(),
                  child: OCLiquidGlassGroup(
                    settings: const OCLiquidGlassSettings(
                      refractStrength: -0.08,
                      blurRadiusPx: 5.0,
                      specStrength: 0,
                      specWidth: 0.0,
                      specAngle: 145,
                      blendPx: 70,
                      specPower: 10,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        kHeavyEffects
                            ? OCLiquidGlass(
                                width: larghezzaBarra,
                                height: 66,
                                borderRadius: 100,
                                color: colors.surfaceHighlight.withValues(
                                  alpha: 0.8,
                                ),
                              )
                            : Container(
                                width: larghezzaBarra,
                                height: 66,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colors.surfaceHighlight,
                                      colors.surfaceRaised,
                                    ],
                                    stops: const [0.2, 1.0],
                                  ),
                                  border: Border.all(color: colors.border),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.shadow,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                        SizedBox(
                          width: larghezzaBarra,
                          height: 66,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: barHorizontalPadding,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(_items.length, (i) {
                                final item = _items[i];
                                return AmNavItem(
                                  icon: item.icon,
                                  iconIsActive: item.activeIcon,
                                  lable: item.label,
                                  onTap: () => goTo(i),
                                  isSelect: selected == i,
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
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

/* class _GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _appOrange.withValues(alpha: 0.4),
          _appOrange.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}*/

class AmNavItem extends StatelessWidget {
  /// Accepts HugeIcons stroke data; IconData remains supported for legacy callers.
  final Object icon;
  final Object iconIsActive;
  final String lable;
  final bool isSelect;
  final VoidCallback onTap;

  const AmNavItem({
    super.key,
    required this.icon,
    required this.iconIsActive,
    required this.lable,
    required this.isSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelect ? 16.0 : 12.0,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          // Background arancione semitrasparente come richiesto
          color: isSelect
              ? colors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelect
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavIcon(
                  value: isSelect ? iconIsActive : icon,
                  color: isSelect ? colors.accent : colors.textPrimary,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: isSelect
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            lable,
                            style: TextStyle(
                              color: colors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Trattino arancione animato sotto l'icona e il testo
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: 3.0,
              width: isSelect ? 24 : 0,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  if (isSelect)
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.5),
                      blurRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final Object value;
  final Color color;

  const _NavIcon({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    if (value is List) {
      return HugeIcon(
        icon: value as List<List>,
        size: 22,
        color: color,
        strokeWidth: 2,
      );
    }
    return Icon(value as IconData, size: 22, color: color);
  }
}
