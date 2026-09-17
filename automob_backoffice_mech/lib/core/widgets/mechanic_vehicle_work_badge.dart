import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// The catalog exposes maintenance status, not an exact job count.
class MechanicVehicleWorkBadge extends StatelessWidget {
  const MechanicVehicleWorkBadge({required this.requiresWork, super.key});

  final bool requiresWork;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final color = requiresWork ? colors.accent : colors.info;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        DecoratedBox(
          key: const Key('mechanic-vehicle-status-circle'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 3),
          ),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              requiresWork ? Icons.warning_amber_rounded : Icons.check_rounded,
              key: const Key('mechanic-vehicle-status-icon'),
              color: color,
              size: 22,
            ),
          ),
        ),
        Text(
          requiresWork ? 'Lavori da fare' : '0 lavori da fare',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
