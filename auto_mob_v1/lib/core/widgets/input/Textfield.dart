import 'package:flutter/material.dart';

/// Campo di testo personalizzato AutoMob.
/// Tutto è controllato dall'esterno: tipo, oscuramento, obbligatorietà.
class AmTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isRequired;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon; // Per passare l'occhio della password o icone di ricerca
  final ValueChanged<String>? onChanged;

  const AmTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.isRequired,
    required this.obscureText,
    required this.keyboardType,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const Color labelColor = Color(0xFF636366);
    const Color asteriskColor = Color(0xFF4A90E2);
    const Color boxColor = Color(0xFF1C1C1E);
    const Color hintColor = Color(0xFF48484A);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label superiore con asterisco condizionale
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
              children: [
                TextSpan(text: label.toUpperCase()),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: asteriskColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Box del TextField
          Container(
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: hintColor,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                suffixIcon: suffixIcon,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}