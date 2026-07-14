import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';

class AmDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final String placeholder;
  final bool isRequired;

  const AmDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.value,
    required this.placeholder ,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: label.toUpperCase()),
                if (isRequired) TextSpan(
                    text: ' *', style: TextStyle(color: colors.info)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(placeholder, style: TextStyle(
                    color: colors.textSecondary, fontSize: 16)),
                icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    color: colors.textSecondary,
                    size: 22,
                    strokeWidth: 2.2),
                isExpanded: true,
                dropdownColor: colors.surface,
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabelBuilder(item), style: TextStyle(
                        color: colors.textPrimary, fontSize: 16)),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
