import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import 'mechanic_shapes.dart';
import 'mechanic_vehicle_work_badge.dart';

enum MechanicVehicleStatus { connected, pending, attention, service }

class MechanicVehicleCardData {
  const MechanicVehicleCardData({
    required this.id,
    required this.name,
    required this.plate,
    required this.year,
    required this.kilometers,
    this.status = MechanicVehicleStatus.connected,
  });

  final String id;
  final String name;
  final String plate;
  final int year;
  final int kilometers;
  final MechanicVehicleStatus status;
}

class MechanicVehicleCard extends StatelessWidget {
  const MechanicVehicleCard({required this.vehicle, super.key, this.onPressed});

  final MechanicVehicleCardData vehicle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final cardShape = mechanicSmoothShape(radius: 24);

    return Semantics(
      button: onPressed != null,
      label: '${vehicle.name}, targa ${vehicle.plate}',
      child: AspectRatio(
        aspectRatio: 1.15,
        child: DecoratedBox(
          key: const Key('mechanic-vehicle-card-corner-border'),
          decoration: ShapeDecoration(
            gradient: colors.cardBorderGradient,
            shape: cardShape,
            shadows: colors.cardShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Material(
              color: colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: cardShape,
              child: InkWell(
                customBorder: cardShape,
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        vehicle.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Center(
                        child: MechanicVehicleWorkBadge(
                          requiresWork:
                              vehicle.status != MechanicVehicleStatus.connected,
                        ),
                      ),
                      Center(
                        child: DecoratedBox(
                          key: const Key('mechanic-vehicle-plate'),
                          decoration: ShapeDecoration(
                            color: colors.surfaceRaised,
                            shape: mechanicSmoothShape(radius: 14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                vehicle.plate.toUpperCase(),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
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
