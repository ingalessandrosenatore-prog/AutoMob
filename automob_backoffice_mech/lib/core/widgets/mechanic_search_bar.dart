import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../router/mechanic_shell_metrics.dart';
import 'mechanic_shapes.dart';

/// Superficie di ricerca condivisa dalle pagine dell'app meccanico.
///
/// Riceve solo input e callback di presentazione; filtro e stato restano nel
/// BLoC della feature che la utilizza.
class MechanicSearchBar extends StatelessWidget {
  const MechanicSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.enabled = true,
    this.end,
    this.repaint,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool enabled;
  final Widget? end;
  final Listenable? repaint;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    const radius = MechanicShellMetrics.searchHeight / 2;
    final shape = mechanicSmoothShape(radius: radius);
    final translucentSurface = colors.surface.withValues(alpha: 0.72);

    return RepaintBoundary(
      child: SizedBox(
        height: MechanicShellMetrics.searchHeight,
        child: DecoratedBox(
          key: const ValueKey('mechanic-search-border-surface'),
          decoration: ShapeDecoration(
            gradient: colors.cardBorderGradient,
            shape: shape,
            shadows: colors.cardShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: mechanicSmoothShape(radius: radius - 1),
              ),
              child: OCLiquidGlassGroup(
                repaint: repaint,
                settings: const OCLiquidGlassSettings(
                  refractStrength: -0.08,
                  blurRadiusPx: 8,
                  specStrength: 2,
                  specWidth: 1,
                  specAngle: 145,
                  specPower: 5,
                  lightbandOffsetPx: 5,
                  lightbandStrength: 1,
                ),
                child: OCLiquidGlass(
                  borderRadius: radius - 1,
                  width: double.infinity,
                  height: MechanicShellMetrics.searchHeight - 2,
                  child: DecoratedBox(
                    key: const ValueKey('mechanic-search-shared-fill'),
                    decoration: BoxDecoration(
                      color: translucentSurface,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            controller: controller,
                            enabled: enabled,
                            onChanged: onChanged,
                            textInputAction: TextInputAction.search,
                            hintText: hintText,
                            hintStyle: WidgetStatePropertyAll(
                              TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            trailing: const <Widget>[],
                            elevation: const WidgetStatePropertyAll(0),
                            backgroundColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            shadowColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            surfaceTintColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                          ),
                        ),
                        ?end,
                      ],
                    ),
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
