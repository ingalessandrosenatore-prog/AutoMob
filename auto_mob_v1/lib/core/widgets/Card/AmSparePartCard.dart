import 'package:flutter/material.dart';
import '../input/Textfield.dart';

/// Card per i pezzi di ricambio nel WorkLog.
/// Estetica: Expandable e Slidable con stile dark.
/// Accetta id, nome e un notifier per la quantità.
class AmSparePartCard extends StatelessWidget {
  final int id;
  final String name;
  final ValueNotifier<int> quantityNotifier;
  final ValueNotifier<bool> isExpandedNotifier;

  const AmSparePartCard({
    super.key,
    required this.id,
    required this.name,
    required this.quantityNotifier,
    required this.isExpandedNotifier,
  });

  @override
  Widget build(BuildContext context) {
    const Color boxColor = Color(0xFF1C1C1E);
    const Color orangeColor = Color(0xFFE85A1A);
    const Color deleteColor = Color(0xFF4A90E2); // Blu come richiesto

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Dismissible(
        key: ValueKey(id),
        direction: DismissDirection.horizontal,
        background: _buildDeleteBackground(deleteColor, Alignment.centerLeft),
        secondaryBackground: _buildDeleteBackground(deleteColor, Alignment.centerRight),
        onDismissed: (_) {
          // Eliminazione gestita esternamente
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: isExpandedNotifier,
          builder: (context, isExpanded, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExpanded ? orangeColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Parte Visibile (Header)
                  InkWell(
                    onTap: () => isExpandedNotifier.value = !isExpanded,
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
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<int>(
                                  valueListenable: quantityNotifier,
                                  builder: (context, quantity, _) {
                                    return RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFF8E8E93),
                                          fontSize: 13,
                                        ),
                                        children: [
                                          const TextSpan(text: "Quantità: "),
                                          TextSpan(
                                            text: "$quantity",
                                            style: const TextStyle(
                                              color: orangeColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: const Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Parte Espandibile
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 20),
                          // Quantità Selector
                          _buildQuantitySelector(orangeColor),
                          const SizedBox(height: 20),
                          // Note
                          Row(
                            children: [
                              AmTextField(
                                label: "Note",
                                placeholder: "es. marca, codice...",
                                controller: TextEditingController(),
                                isRequired: false,
                                obscureText: false,
                                keyboardType: TextInputType.text,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Prezzo Unitario
                          Row(
                            children: [
                              AmTextField(
                                label: "Prezzo Unitario",
                                placeholder: "0,00",
                                controller: TextEditingController(),
                                isRequired: false,
                                obscureText: false,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                suffixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text("€", 
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
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(Color color, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Rilascia per eliminare",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(Color orangeColor) {
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
              _buildCircleBtn(Icons.remove, const Color(0xFF2C2C2E)),
              const SizedBox(width: 20),
              ValueListenableBuilder<int>(
                valueListenable: quantityNotifier,
                builder: (context, quantity, _) {
                  return Text(
                    "$quantity",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              _buildCircleBtn(Icons.add, orangeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: color != const Color(0xFF2C2C2E) ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : [],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
