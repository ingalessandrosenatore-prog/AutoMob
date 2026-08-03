import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

import 'mechanic_shapes.dart';

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
    final statusColor = vehicle.status.color(colors);
    final cardShape = mechanicSmoothShape(
      radius: 30,
      side: BorderSide(color: colors.border),
    );

    return Semantics(
      button: onPressed != null,
      label: '${vehicle.name}, targa ${vehicle.plate}',
      child: DecoratedBox(
        decoration: ShapeDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.1, -0.8),
            radius: 1.35,
            colors: [
              statusColor.withValues(alpha: 0.34),
              colors.surface.withValues(alpha: 0.96),
            ],
            stops: const [0, 0.72],
          ),
          shadows: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          shape: cardShape,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: cardShape,
          child: InkWell(
            customBorder: cardShape,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _VehicleStatusBadge(
                        status: vehicle.status,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(color: colors.border.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _VehicleMetadataChip(label: vehicle.plate.toUpperCase()),
                      _VehicleMetadataChip(label: '${vehicle.year}'),
                      _VehicleMetadataChip(
                        label: '${_formatKilometers(vehicle.kilometers)} KM',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatKilometers(int value) {
    final digits = value.toString();
    final chunks = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = (end - 3).clamp(0, digits.length);
      chunks.insert(0, digits.substring(start, end));
    }
    return chunks.join('.');
  }
}

class _VehicleStatusBadge extends StatelessWidget {
  const _VehicleStatusBadge({required this.status, required this.color});

  final MechanicVehicleStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 18),
      ],
    ),
    child: Icon(status.icon, color: color, size: 25),
  );
}

class _VehicleMetadataChip extends StatelessWidget {
  const _VehicleMetadataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.64),
        shape: mechanicSmoothShape(radius: 10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.25,
          ),
        ),
      ),
    );
  }
}

extension on MechanicVehicleStatus {
  IconData get icon => switch (this) {
    MechanicVehicleStatus.connected => Icons.check_rounded,
    MechanicVehicleStatus.pending => Icons.schedule_rounded,
    MechanicVehicleStatus.attention => Icons.warning_amber_rounded,
    MechanicVehicleStatus.service => Icons.build_rounded,
  };

  Color color(AmThemeColors colors) => switch (this) {
    MechanicVehicleStatus.connected => colors.info,
    MechanicVehicleStatus.pending => colors.accent,
    MechanicVehicleStatus.attention => colors.accent,
    MechanicVehicleStatus.service => colors.info,
  };
}
