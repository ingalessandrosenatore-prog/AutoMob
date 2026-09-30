import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/mechanic_search_bar.dart';
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
    return MechanicSearchBar(
      enabled: enabled,
      controller: controller,
      onChanged: onSearchChanged,
      hintText: 'Cerca targa, marca o modello...',
      repaint: repaint,
      end: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      ),
    );
  }
}
