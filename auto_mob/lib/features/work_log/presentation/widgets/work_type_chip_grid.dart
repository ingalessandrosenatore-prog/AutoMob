import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/core/widgets/icons/am_engine_icon.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class WorkTypeChipGrid extends StatelessWidget {
  final EnumPopUp? selectedType;
  final ValueChanged<EnumPopUp?> onChanged;

  const WorkTypeChipGrid({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELEZIONA TIPO INTERVENTO:',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final type in EnumPopUp.values)
              _WorkTypeChip(
                type: type,
                selected: selectedType == type,
                onTap: () => onChanged(selectedType == type ? null : type),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorkTypeChip extends StatelessWidget {
  final EnumPopUp type;
  final bool selected;
  final VoidCallback onTap;

  const _WorkTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final background = selected ? colors.accent : colors.surface;
    final foreground = selected ? colors.onMedia : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.accent
                  : colors.surfaceHighlight.withValues(alpha: .55),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.onMedia.withValues(alpha: .16)
                      : colors.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: _WorkTypeIcon(type: type, size: 18, color: foreground),
              ),
              const SizedBox(width: 8),
              Text(
                type.workTypeLabel,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension WorkTypeChipPresentation on EnumPopUp {
  String get workTypeLabel => switch (this) {
    EnumPopUp.aggiornaTagliando => 'Tagliando',
    EnumPopUp.aggiornaDistribuzione => 'Distribuzione',
    EnumPopUp.aggiornaCambioGomme => 'Cambio gomme',
    EnumPopUp.revisione => 'Revisione',
    EnumPopUp.pneumaticiInversione => 'Inversione gomme',
    EnumPopUp.altro => 'Altro',
  };
}

class _WorkTypeIcon extends StatelessWidget {
  final EnumPopUp type;
  final double size;
  final Color color;

  const _WorkTypeIcon({
    required this.type,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => switch (type) {
    EnumPopUp.aggiornaTagliando => HugeIcon(
      icon: HugeIcons.strokeRoundedTools,
      size: size,
      color: color,
      strokeWidth: 2.2,
    ),
    EnumPopUp.aggiornaDistribuzione => AmEngineIcon(size: size, color: color),
    EnumPopUp.aggiornaCambioGomme => HugeIcon(
      icon: HugeIcons.strokeRoundedTire,
      size: size,
      color: color,
      strokeWidth: 2.2,
    ),
    EnumPopUp.pneumaticiInversione => HugeIcon(
      icon: HugeIcons.strokeRoundedRefresh,
      size: size,
      color: color,
      strokeWidth: 2.2,
    ),
    EnumPopUp.revisione => HugeIcon(
      icon: HugeIcons.strokeRoundedValidation,
      size: size,
      color: color,
      strokeWidth: 2.2,
    ),
    EnumPopUp.altro => HugeIcon(
      icon: HugeIcons.strokeRoundedMoreHorizontalCircle02,
      size: size,
      color: color,
      strokeWidth: 2.2,
    ),
  };
}
