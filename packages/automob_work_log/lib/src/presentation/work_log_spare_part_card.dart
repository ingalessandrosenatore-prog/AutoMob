import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../domain/work_log_draft.dart';

class _ExpansionCubit extends Cubit<bool> {
  _ExpansionCubit() : super(false);
  void toggle() => emit(!state);
  void collapse() {
    if (state) emit(false);
  }
}

/// Card ricambio originale AutoMob, adattata al draft del package.
class WorkLogSparePartCard extends StatefulWidget {
  const WorkLogSparePartCard({
    required this.item,
    required this.name,
    required this.onRemove,
    required this.onItemChanged,
    super.key,
  });

  final WorkLogPartDraft item;
  final String name;
  final VoidCallback onRemove;
  final ValueChanged<WorkLogPartDraft> onItemChanged;

  @override
  State<WorkLogSparePartCard> createState() => _WorkLogSparePartCardState();
}

class _WorkLogSparePartCardState extends State<WorkLogSparePartCard> {
  final _expansion = _ExpansionCubit();
  late final TextEditingController _notes;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.item.notes ?? '');
    _price = TextEditingController(
      text: widget.item.unitPrice?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant WorkLogSparePartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.partId != widget.item.partId) {
      _notes.text = widget.item.notes ?? '';
      _price.text = widget.item.unitPrice?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _price.dispose();
    _expansion.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocBuilder<_ExpansionCubit, bool>(
      bloc: _expansion,
      builder: (context, expanded) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Dismissible(
          key: ValueKey(widget.item.partId),
          direction: DismissDirection.horizontal,
          background: _DeleteBackground(
            color: colors.danger,
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _DeleteBackground(
            color: colors.danger,
            alignment: Alignment.centerRight,
          ),
          onDismissed: (_) => widget.onRemove(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: expanded
                    ? colors.accent.withValues(alpha: 0.3)
                    : colors.border,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _expansion.toggle,
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
                                    const TextSpan(text: 'Quantità: '),
                                    TextSpan(
                                      text: _quantity(widget.item.quantity),
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
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 260),
                          turns: expanded ? 0.5 : 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.surfaceRaised,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowDown01,
                              color: colors.textSecondary,
                              size: 20,
                              strokeWidth: 2.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: expanded
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _expansion.collapse,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(color: colors.border, height: 1),
                                const SizedBox(height: 20),
                                _QuantitySelector(
                                  quantity: widget.item.quantity.toInt(),
                                  onChanged: (quantity) => widget.onItemChanged(
                                    widget.item.copyWith(
                                      quantity: quantity.toDouble(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    AmTextField(
                                      key: ValueKey(
                                        'part-notes-${widget.item.partId}',
                                      ),
                                      label: 'Note',
                                      placeholder: 'es. marca, codice...',
                                      controller: _notes,
                                      isRequired: false,
                                      obscureText: false,
                                      keyboardType: TextInputType.text,
                                      onChanged: (value) =>
                                          widget.onItemChanged(
                                            widget.item.copyWith(
                                              notes: value,
                                              clearNotes: value.trim().isEmpty,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    AmTextField(
                                      key: ValueKey(
                                        'part-price-${widget.item.partId}',
                                      ),
                                      label: 'Prezzo unitario',
                                      placeholder: '0,00',
                                      controller: _price,
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
                                      onChanged: (value) {
                                        final normalized = value.replaceAll(
                                          ',',
                                          '.',
                                        );
                                        widget.onItemChanged(
                                          widget.item.copyWith(
                                            unitPrice: double.tryParse(
                                              normalized,
                                            ),
                                            clearUnitPrice: normalized
                                                .trim()
                                                .isEmpty,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.color, required this.alignment});
  final Color color;
  final Alignment alignment;

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
        SizedBox(width: 6),
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

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({required this.quantity, required this.onChanged});
  final int quantity;
  final ValueChanged<int> onChanged;

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
            'QUANTITÀ',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          Row(
            children: [
              _CircleButton(
                icon: HugeIcons.strokeRoundedMinusSign,
                color: colors.surfaceRaised,
                onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
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
              _CircleButton(
                icon: HugeIcons.strokeRoundedAdd01,
                color: colors.accent,
                elevated: true,
                onTap: () => onChanged(quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.elevated = false,
  });
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
