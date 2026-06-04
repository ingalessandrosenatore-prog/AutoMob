import 'package:auto_mob_v1/core/widgets/Buttons/AmAnimatedNavButton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class ShellScaffold extends StatefulWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  State<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<ShellScaffold> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));


  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C23),
      body: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: RepaintBoundary(
                child: OCLiquidGlassGroup(
                  settings: OCLiquidGlassSettings(
                    blurRadiusPx: 20,
                    specWidth: 0.00,
                    specStrength: 0,
                    specAngle: 45,


                  ),
                  child: OCLiquidGlass(
                    width: 320,
                    height: 80,
                    borderRadius: 100,
                    child: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AmAnimatedNavButton(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home,
                            label: 'GARAGE',
                            activeColor: const Color(0xFFFF6B00),
                            isSelected: location == '/home',
                            onTap: () {
                              _handleTap();
                              context.go('/home');
                            },
                          ),
                          const SizedBox(width: 8),
                          AmAnimatedNavButton(
                            icon: Icons.build_outlined,
                            activeIcon: Icons.build,
                            label: 'LAVORI',
                            activeColor: const Color(0xFFFF6B00),
                            isSelected: location == '/lavori',
                            onTap: () {
                              _handleTap();
                              context.go('/lavori');
                            },
                          ),
                          const SizedBox(width: 8),
                          AmAnimatedNavButton(
                            icon: Icons.list_rounded,
                            activeIcon: Icons.list_sharp,
                            label: 'SERVIZI',
                            activeColor: const Color(0xFFFF6B00),
                            isSelected: location == '/servizi',
                            onTap: () {
                              _handleTap();
                              context.go('/servizi');
                            },
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
