import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../../../core/router/mechanic_shell_metrics.dart';
import '../../../../core/widgets/mechanic_shapes.dart';
import '../bloc/workshop_vehicle_filter.dart';

/// Campo di ricerca e filtro della lista veicoli.
///
/// Le callback rappresentano eventi di presentazione: il widget non conosce
/// il BLoC e quindi resta riutilizzabile senza introdurre dipendenze di stato.
class WorkshopSearchControls extends StatelessWidget {
  const WorkshopSearchControls({
    super.key,
    required this.enabled,
    required this.controller,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    this.repaint,
  });

  final bool enabled;
  final TextEditingController controller;
  final WorkshopVehicleFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<WorkshopVehicleFilter> onFilterChanged;
  final Listenable? repaint;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    const radius = MechanicShellMetrics.searchHeight / 2;
    final shape = mechanicSmoothShape(radius: radius);
    return RepaintBoundary(
      child: SizedBox(
        height: MechanicShellMetrics.searchHeight,
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: OCLiquidGlassGroup(
            repaint: repaint,
            settings: const OCLiquidGlassSettings(
              refractStrength: -0.08,
              blurRadiusPx: 2,
              specStrength: 2,
              specWidth: 1,
              specAngle: 145,
              specPower: 5,
              lightbandOffsetPx: 7,
              lightbandStrength: 0.5,
            ),
            child: OCLiquidGlass(
              borderRadius: radius,
              width: double.infinity,
              height: MechanicShellMetrics.searchHeight,
              color: colors.background.withValues(alpha: 0.30),

              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: controller,
                      enabled: enabled,
                      onChanged: onSearchChanged,
                      textInputAction: TextInputAction.search,
                      hintText: 'Cerca targa, marca o modello...',
                      hintStyle: WidgetStatePropertyAll(
                        TextStyle(color: colors.textPrimary, fontSize: 15),
                      ),
                      textStyle: WidgetStatePropertyAll(
                        TextStyle(color: colors.textPrimary, fontSize: 15),
                      ),
                      trailing: <Widget>[],
                      // SearchBar is transparent because the parent glass
                      // surface owns the single visible background.
                      backgroundColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 1,
                    height: 24,
                    child: ColoredBox(
                      color: colors.border.withValues(alpha: 0.7),
                    ),
                  ),
                  PopupMenuButton<WorkshopVehicleFilter>(
                    key: const ValueKey('workshop_filter_button'),
                    enabled: enabled,
                    initialValue: filter,
                    tooltip: 'Filtra veicoli',
                    onSelected: onFilterChanged,
                    color: colors.surfaceRaised,
                    icon: Icon(
                      Icons.tune_rounded,
                      color: filter == WorkshopVehicleFilter.all
                          ? colors.textPrimary
                          : colors.accent,
                    ),
                    itemBuilder: (context) => WorkshopVehicleFilter.values
                        .map(
                          (value) => PopupMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
