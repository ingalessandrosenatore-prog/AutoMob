import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../widgets/mechanic_shapes.dart';
import 'mechanic_shell_metrics.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
    this.liquidGlassEnabled = true,
  });

  final StatefulNavigationShell navigationShell;
  final bool liquidGlassEnabled;

  void _selectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final controlsBottom = math.max(
      MediaQuery.paddingOf(context).bottom,
      MechanicShellMetrics.bottomMargin,
    );
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: colors.background,
      body: MechanicShellGeometry(
        controlsBottom: controlsBottom,
        child: navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          MechanicShellMetrics.horizontalMargin,
          8,
          MechanicShellMetrics.horizontalMargin,
          MechanicShellMetrics.bottomMargin,
        ),
        child: SizedBox(
          key: const ValueKey('mechanic_bottom_navigation'),
          height: MechanicShellMetrics.navigationHeight,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _NavigationSurface(
                  liquidGlassEnabled: liquidGlassEnabled,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: _ShellDestination(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          selected: navigationShell.currentIndex == 0,
                          liquidGlassEnabled: liquidGlassEnabled,
                          onPressed: () => _selectBranch(0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ShellDestination(
                          label: 'Servizi',
                          icon: Icons.build_rounded,
                          selected: navigationShell.currentIndex == 1,
                          liquidGlassEnabled: liquidGlassEnabled,
                          onPressed: () => _selectBranch(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: MechanicShellMetrics.controlSpacing),
              const SizedBox(width: MechanicShellMetrics.microphoneSize),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationSurface extends StatelessWidget {
  const _NavigationSurface({
    required this.liquidGlassEnabled,
    required this.child,
  });

  final bool liquidGlassEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    const radius = MechanicShellMetrics.navigationHeight / 2;
    final shape = mechanicSmoothShape(radius: radius);
    final content = Padding(padding: const EdgeInsets.all(6), child: child);

    // The outer clip is intentional: it bounds the glass render layer itself,
    // so Android cannot expose the rectangular offscreen texture.
    return RepaintBoundary(
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: OCLiquidGlassGroup(
          settings: const OCLiquidGlassSettings(
            refractStrength: -0.08,
            blurRadiusPx: 2,
            specStrength: 1,
            specWidth: 2,
            specAngle: 145,
            specPower: 10,
            lightbandOffsetPx: 7,
            lightbandStrength: 0.5,
          ),
          child: OCLiquidGlass(
            borderRadius: radius,
            color: colors.background.withValues(alpha: 0.30),
            child: content,
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
    required this.liquidGlassEnabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool liquidGlassEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final foreground = selected ? colors.accent : colors.textSecondary;
    const radius = (MechanicShellMetrics.navigationHeight - 12) / 2;
    final destinationShape = mechanicSmoothShape(radius: radius);
    final content = InkWell(
      customBorder: destinationShape,
      onTap: onPressed,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 10,
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
          ? DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                shape: destinationShape,
              ),
              child: content,
            )
          : content,
    );
  }
}
