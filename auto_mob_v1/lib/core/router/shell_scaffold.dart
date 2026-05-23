import 'package:auto_mob_v1/core/widgets/Buttons/AmAnimatedNavButton.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C23),
      body: Stack(
        children: [
          child,
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AmAnimatedNavButton(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'GARAGE',
                    activeColor: const Color(0xFFFF6B00),
                    isSelected: location == '/home',
                    onTap: () => context.go('/home'),
                  ),
                  const SizedBox(width: 8),
                  AmAnimatedNavButton(
                    icon: Icons.build_outlined,
                    activeIcon: Icons.build,
                    label: 'LAVORI',
                    activeColor: const Color(0xFF3192F3),
                    isSelected: location == '/lavori',
                    onTap: () => context.go('/lavori'),
                  ),
                  const SizedBox(width: 8),
                  AmAnimatedNavButton(
                    icon: Icons.list_rounded,
                    activeIcon: Icons.list_sharp,
                    label: 'SERVIZI',
                    activeColor: const Color(0xFF7361AC),
                    isSelected: location == '/servizi',
                    onTap: () => context.go('/servizi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
