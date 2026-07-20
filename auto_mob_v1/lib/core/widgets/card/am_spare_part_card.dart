import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';
import '../input/textfield.dart';

class AmSparePartCard extends StatefulWidget {
  final SelectedPart item;
  final String name;
  final VoidCallback onRemove;
  final ValueChanged<SelectedPart> onItemChanged;

  const AmSparePartCard({
    super.key,
    required this.item,
    required this.name,
    required this.onRemove,
    required this.onItemChanged,
  });

  @override
  State<AmSparePartCard> createState() => _AmSparePartCardState();
}

class _AmSparePartCardState extends State<AmSparePartCard> {
  bool _isExpanded = false;
  late final TextEditingController _noteController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.note ?? '');
    _priceController = TextEditingController(
      text: widget.item.unitPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Dismissible(
        key: ValueKey(item.partId),
        direction: DismissDirection.horizontal,
        background: _PartDeleteBackground(
          color: colors.danger,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _PartDeleteBackground(
          color: colors.danger,
          alignment: Alignment.centerRight,
        ),
        onDismissed: (_) => widget.onRemove(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isExpanded
                  ? colors.accent.withValues(alpha: 0.3)
                  : colors.border,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(text: 'Quantita: '),
                                  TextSpan(
                                    text: '${item.quantity.toInt()}',
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: HugeIcon(
                          icon: _isExpanded
                              ? HugeIcons.strokeRoundedArrowUp01
                              : HugeIcons.strokeRoundedArrowDown01,
                          color: colors.textSecondary,
                          size: 20,
                          strokeWidth: 2.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isExpanded = false),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: colors.border, height: 1),
                        const SizedBox(height: 20),
                        _PartQuantitySelector(
                          quantity: item.quantity.toInt(),
                          accentColor: colors.accent,
                          onQuantityChanged: (quantity) => widget.onItemChanged(
                            item.copyWith(quantity: quantity.toDouble()),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            AmTextField(
                              label: 'Note',
                              placeholder: 'es. marca, codice...',
                              controller: _noteController,
                              isRequired: false,
                              obscureText: false,
                              keyboardType: TextInputType.text,
                              onEditingComplete: () => widget.onItemChanged(
                                item.copyWith(note: _noteController.text),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            AmTextField(
                              label: 'Prezzo unitario',
                              placeholder: '0,00',
                              controller: _priceController,
                              isRequired: false,
                              obscureText: false,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              suffixIcon: Text(
                                'EUR',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onChanged: (value) => widget.onItemChanged(
                                item.copyWith(
                                  unitPrice: double.tryParse(
                                    value.toString().replaceAll(',', '.'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartDeleteBackground extends StatelessWidget {
  final Color color;
  final Alignment alignment;

  const _PartDeleteBackground({required this.color, required this.alignment});

  @override
  Widget build(BuildContext context) => Container(
    alignment: alignment,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Elimina',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          color: Colors.white,
          size: 18,
          strokeWidth: 2.2,
        ),
      ],
    ),
  );
}

class _PartQuantitySelector extends StatelessWidget {
  final int quantity;
  final Color accentColor;
  final ValueChanged<int> onQuantityChanged;

  const _PartQuantitySelector({
    required this.quantity,
    required this.accentColor,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'QUANTITA',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          Row(
            children: [
              _PartCircleButton(
                icon: HugeIcons.strokeRoundedMinusSign,
                color: colors.surfaceRaised,
                onTap: quantity > 1
                    ? () => onQuantityChanged(quantity - 1)
                    : null,
                colors: colors,
              ),
              const SizedBox(width: 20),
              Text(
                '$quantity',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              _PartCircleButton(
                icon: HugeIcons.strokeRoundedAdd01,
                color: accentColor,
                elevated: true,
                onTap: () => onQuantityChanged(quantity + 1),
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartCircleButton extends StatelessWidget {
  final List<List> icon;
  final Color color;
  final VoidCallback? onTap;
  final bool elevated;
  final AmThemeColors colors;

  const _PartCircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.elevated = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: HugeIcon(
        icon: icon,
        color: colors.textPrimary,
        size: 20,
        strokeWidth: 2.2,
      ),
    ),
  );
}
