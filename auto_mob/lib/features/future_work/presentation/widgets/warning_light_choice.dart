import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

/// One square selection target per generic dashboard symbol.
class WarningLightChoice extends StatelessWidget {
  const WarningLightChoice({
    required this.light,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final AmWarningLightData light;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: EdgeInsets.zero,
      backgroundColor: colors.surface,
      selectedColor: light.tint.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected ? light.tint : colors.borderHighlight,
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      label: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IgnorePointer(child: AmWarningLight(light: light, size: 40)),
              const SizedBox(height: 10),
              Text(
                light.variantLabel,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
