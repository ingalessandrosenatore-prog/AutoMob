import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';

const Color _appOrange = Color(0xFFFF6B00);

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

class _ShellScaffoldState extends State<ShellScaffold> with TickerProviderStateMixin {
  late final AnimationController bounceCtrl;
  final ValueNotifier<Offset?> _tapPositionNotifier = ValueNotifier<Offset?>(null);

  static final SpringDescription _springDescription = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 300),
    bounce: 0.1,
  );

  static const List<_NavItem> _items = [
    _NavItem(route: '/home', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Garage'),
    _NavItem(route: '/lavori', icon: Icons.build_outlined, activeIcon: Icons.build, label: 'Lavori'),
    _NavItem(route: '/servizi', icon: Icons.list_sharp, activeIcon: Icons.list, label: 'Servizi'),
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
    final location = GoRouterState.of(context).uri.path;
    var selected = _items.indexWhere((it) => location.startsWith(it.route));
    if (selected == -1) selected = 0;

    final larghezzaSchermo = MediaQuery.sizeOf(context).width;
    final margine = (larghezzaSchermo * 12) / 100;
    const maxLarghezza = 500.0;
    final larghezzaBarra = math.min(larghezzaSchermo - 2 * margine, maxLarghezza);

    void goTo(int index) {
      if (index < 0 || index >= _items.length) return;
      context.go(_items[index].route);
    }

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: bounceCtrl,
                builder: (context, child) => Transform.scale(
                  scale: bounceCtrl.value,
                  child: child,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (_) => _onPress(),
                  onPanEnd: (event) {
                    final dito = event.localPosition;
                    final itemWidth = larghezzaBarra / _items.length;
                    final indice = (dito.dx / itemWidth).floor().clamp(0, _items.length - 1);
                    goTo(indice);
                    _onRelese();
                  },
                  onPanCancel: () => _onRelese(),
                  child: Container(
                    width: larghezzaBarra,
                    height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C23).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _GradientBorderPainter(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Row(
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

class _GradientBorderPainter extends CustomPainter {
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
}

class AmNavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconIsActive;
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C2C2E), // Grigio scuro leggermente più chiaro
                Color(0xEF151414), // Grigio molto scuro
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                blurRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelect ? iconIsActive : icon,
                    size: 24,
                    color: isSelect ? _appOrange : Colors.white.withValues(alpha: 0.6),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: isSelect
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              lable,
                              style: const TextStyle(
                                color: _appOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 2.5,
                width: isSelect ? 18 : 0,
                decoration: BoxDecoration(
                  color: _appOrange,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (isSelect)
                      BoxShadow(
                        color: _appOrange.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
