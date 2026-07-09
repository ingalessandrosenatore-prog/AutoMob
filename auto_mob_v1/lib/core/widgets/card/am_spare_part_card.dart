import 'package:auto_mob_v1/features/work_log/domain/entities/selected_part.dart';
import 'package:flutter/material.dart';
import '../input/textfield.dart';

class AmSparePartCard extends StatefulWidget {
  final SelectedPart item;
  final String name;
  final VoidCallback onRemove;
  final void Function(SelectedPart) onItemChanged;

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
    _priceController = TextEditingController(text: widget.item.unitPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color boxColor = Color(0xFF1C1C1E);
    const Color orangeColor = Color(0xFFE85A1A);
    const Color deleteColor = Color(0xFF4A90E2);
    final item = widget.item;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Dismissible(
        key: ValueKey(item.partId),
        direction: DismissDirection.horizontal,
        background: _buildDeleteBackground(deleteColor, Alignment.centerLeft),
        secondaryBackground: _buildDeleteBackground(deleteColor, Alignment.centerRight),
        onDismissed: (_) => widget.onRemove(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isExpanded ? orangeColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                                children: [
                                  const TextSpan(text: "Quantità: "),
                                  TextSpan(
                                    text: "${item.quantity.toInt()}",
                                    style: const TextStyle(
                                      color: orangeColor,
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
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF8E8E93),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Sezione espandibile.
              // GestureDetector: un tap sullo spazio vuoto del corpo chiude la card.
              // I controlli interattivi (bottoni quantità, textfield) assorbono il
              // proprio tap, quindi NON fanno chiudere la card — come le chip in alto.
              if (_isExpanded) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isExpanded = false),
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 20),
                      _buildQuantitySelector(orangeColor),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          AmTextField(
                            label: "Note",
                            placeholder: "es. marca, codice...",
                            controller: _noteController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: TextInputType.text,
                            onEditingComplete: () => widget.onItemChanged(
                              widget.item.copyWith(note: _noteController.text),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          AmTextField(
                            label: "Prezzo Unitario",
                            placeholder: "0,00",
                            controller: _priceController,
                            isRequired: false,
                            obscureText: false,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onEditingComplete: () => widget.onItemChanged(
                              widget.item.copyWith(
                                unitPrice: double.tryParse(_priceController.text.replaceAll(',', '.')),
                              ),
                            ),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "€",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(Color color, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Elimina",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
          ),
          Icon(Icons.delete, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(Color orangeColor) {
    final qty = widget.item.quantity.toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F11),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "QUANTITÀ",
            style: TextStyle(
              color: Color(0xFF636366),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          Row(
            children: [
              _buildCircleBtn(Icons.remove, const Color(0xFF2C2C2E), () {
                if (qty > 1) {
                  widget.onItemChanged(widget.item.copyWith(quantity: (qty - 1).toDouble()));
                }
              }),
              const SizedBox(width: 20),
              Text(
                "$qty",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 20),
              _buildCircleBtn(Icons.add, orangeColor, () {
                widget.onItemChanged(widget.item.copyWith(quantity: (qty + 1).toDouble()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: color != const Color(0xFF2C2C2E)
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

}
