import 'package:flutter/material.dart';

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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF636366),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: label.toUpperCase()),
                if (isRequired) const TextSpan(
                    text: ' *', style: TextStyle(color: Color(0xFF4A90E2))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(placeholder, style: const TextStyle(
                    color: Color(0xFF48484A), fontSize: 16)),
                icon: const Icon(
                    Icons.keyboard_arrow_down, color: Color(0xFF48484A)),
                isExpanded: true,
                dropdownColor: const Color(0xFF1C1C1E),
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabelBuilder(item), style: const TextStyle(
                        color: Colors.white, fontSize: 16)),
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