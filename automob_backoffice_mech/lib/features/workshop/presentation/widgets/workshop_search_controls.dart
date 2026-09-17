import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
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
    this.gradient,
  });

  final bool enabled;
  final TextEditingController controller;
  final WorkshopVehicleFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<WorkshopVehicleFilter> onFilterChanged;
  final Listenable? repaint;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    const radius = MechanicShellMetrics.searchHeight / 2;
    final shape = mechanicSmoothShape(radius: radius);
    final content = Row(
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
            trailing: const <Widget>[],
            elevation: WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(colors.surface),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
        Tooltip(
          message: 'Filtra veicoli',
          child: AmPullDownLG(
            key: const ValueKey('workshop_filter_button'),
            brand: "",
            lable: "",
            backgroundColor: AmControlMetrics.pullDownFill(
              Theme.of(context).brightness,
            ),
            popupBackgroundColor: AmControlMetrics.pullDownPopupFill(
              Theme.of(context).brightness,
            ),
            ownsLiquidGlassGroup: false,
            onTap: () {},
            buttonIcons: HugeIcons.strokeRoundedFilterMail,
            buttonIconsSize: AmControlMetrics.pullDownIconSize,
            iconColor: colors.textPrimary,
            textColor: colors.textPrimary,
            buttonLableStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
            arrow: false,
            children: WorkshopVehicleFilter.values.map((value) {
              return ItemMorphPopUp(
                onTap: () => onFilterChanged(value),
                text: value.label,
                icon: HugeIcons.strokeRoundedTools,
                textColor: colors.textPrimary,
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
    return RepaintBoundary(
      child: SizedBox(
        height: MechanicShellMetrics.searchHeight,
        child: DecoratedBox(
          key: const ValueKey('workshop-search-border-surface'),
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
                  blurRadiusPx: 3,
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
                  child: ColoredBox(
                    key: const ValueKey('workshop-search-shared-fill'),
                    color: colors.surface,
                    child: content,
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
