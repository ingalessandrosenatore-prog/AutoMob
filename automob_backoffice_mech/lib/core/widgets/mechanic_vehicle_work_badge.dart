import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// Badge circolare flottante a cavallo del bordo sinistro della card
/// (nella posizione del cerchio "75%" del design di riferimento), con
/// triangolino arancione o spunta blu.
class MechanicVehicleWorkBadge extends StatelessWidget {
  const MechanicVehicleWorkBadge({required this.requiresWork, super.key});

  final bool requiresWork;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final accentColor = requiresWork ? colors.accent : colors.info;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: DecoratedBox(
          key: const Key('mechanic-vehicle-status-circle'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.10),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.55),
              width: 2.5,
            ),
          ),
          child: SizedBox.square(
            dimension: 42,
            child: Icon(
              requiresWork ? Icons.warning_amber_rounded : Icons.check_rounded,
              key: const Key('mechanic-vehicle-status-icon'),
              color: accentColor,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
