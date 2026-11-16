import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/mechanic_shapes.dart';
import '../bloc/workshop_vehicle_filter.dart';

/// Barra di filtro rapido sopra la lista veicoli con i tre stati:
/// Tutti, OK e Segnalazioni.
class WorkshopStatusFilterBar extends StatelessWidget {
  const WorkshopStatusFilterBar({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.okCount,
    required this.dueCount,
    required this.onFilterSelected,
  });

  final WorkshopVehicleFilter selectedFilter;
  final int totalCount;
  final int okCount;
  final int dueCount;
  final ValueChanged<WorkshopVehicleFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Row(
      key: const ValueKey('workshop_status_filter_bar'),
      children: [
        Expanded(
          child: _WorkshopFilterTile(
            key: const ValueKey('workshop_filter_all'),
            label: WorkshopVehicleFilter.all.label,
            count: totalCount,
            icon: Icons.grid_view_rounded,
            toneColor: colors.accentSecondary,
            labelColor: colors.textPrimary,
            selected: selectedFilter == WorkshopVehicleFilter.all,
            onTap: () => onFilterSelected(WorkshopVehicleFilter.all),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WorkshopFilterTile(
            key: const ValueKey('workshop_filter_ok'),
            label: WorkshopVehicleFilter.connected.label,
            count: okCount,
            icon: Icons.check_circle_outline_rounded,
            toneColor: colors.info,
            selected: selectedFilter == WorkshopVehicleFilter.connected,
            onTap: () => onFilterSelected(WorkshopVehicleFilter.connected),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _WorkshopFilterTile(
            key: const ValueKey('workshop_filter_due'),
            label: WorkshopVehicleFilter.maintenanceDue.label,
            count: dueCount,
            icon: Icons.warning_amber_rounded,
            toneColor: colors.accent,
            selected: selectedFilter == WorkshopVehicleFilter.maintenanceDue,
            onTap: () => onFilterSelected(WorkshopVehicleFilter.maintenanceDue),
          ),
        ),
      ],
    );
  }
}

class _WorkshopFilterTile extends StatelessWidget {
  const _WorkshopFilterTile({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.toneColor,
    this.labelColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color toneColor;
  final Color? labelColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final shape = mechanicSmoothShape(
      radius: 14,
      side: BorderSide(
        color: selected
            ? Color.lerp(toneColor, Colors.white, 0.45)!
            : toneColor.withValues(alpha: 0.28),
        width: selected ? 1.5 : 1.0,
      ),
    );
    final foregroundColor = labelColor ?? (selected ? Colors.white : toneColor);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count',
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          color: selected ? null : Color.lerp(colors.surface, toneColor, 0.08),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(toneColor, Colors.white, 0.12)!,
                    Color.lerp(toneColor, Colors.black, 0.18)!,
                  ],
                )
              : null,
          shadows: selected
              ? [
                  BoxShadow(
                    color: toneColor.withValues(alpha: 0.34),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: mechanicMinimumTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foregroundColor, size: 16),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foregroundColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count',
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
