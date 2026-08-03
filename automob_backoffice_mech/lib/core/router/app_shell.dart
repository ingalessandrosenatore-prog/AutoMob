import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../widgets/mechanic_shapes.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _selectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 74,
          child: OCLiquidGlassGroup(
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.12,
              blurRadiusPx: 3,
              specStrength: 0.16,
              specWidth: 0.8,
              specAngle: 145,
              blendPx: 28,
              specPower: 12,
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: mechanicSmoothShape(radius: 30),
              ),
              child: OCLiquidGlass(
                borderRadius: 30,
                color: colors.surfaceRaised.withValues(alpha: 0.24),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ShellDestination(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          selected: navigationShell.currentIndex == 0,
                          onPressed: () => _selectBranch(0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ShellDestination(
                          label: 'Servizi',
                          icon: Icons.build_rounded,
                          selected: navigationShell.currentIndex == 1,
                          onPressed: () => _selectBranch(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellDestination extends StatelessWidget {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final foreground = selected ? colors.accent : colors.textSecondary;
    final destinationShape = mechanicSmoothShape(radius: 24);
    final content = InkWell(
      customBorder: destinationShape,
      onTap: onPressed,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 25),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: selected
          ? ClipPath(
              clipper: ShapeBorderClipper(shape: destinationShape),
              child: OCLiquidGlass(
                borderRadius: 24,
                color: colors.accent.withValues(alpha: 0.16),
                child: content,
              ),
            )
          : content,
    );
  }
}
