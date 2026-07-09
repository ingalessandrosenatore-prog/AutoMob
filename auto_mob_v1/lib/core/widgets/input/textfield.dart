import 'package:flutter/material.dart';

/// Campo di testo personalizzato AutoMob.
/// Tutto è controllato dall'esterno: tipo, oscuramento, obbligatorietà.
///
/// Quando [obscureText] è true il campo è trattato come password: mostra da
/// solo un pulsante "occhietto" che alterna testo visibile/nascosto (stato
/// locale, gestito internamente — l'eventuale [suffixIcon] passato dall'esterno
/// viene ignorato in questo caso).
class AmTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isRequired;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<dynamic>? onChanged;
  final VoidCallback? onEditingComplete;

  /// Messaggio mostrato SOTTO il campo. Null = niente messaggio.
  /// Puo' essere un errore (rosso acceso) o un semplice avviso (rosso tenue):
  /// il colore lo decide `errorColor`.
  final String? errorText;

  /// Colore del messaggio sotto il campo. Default: rosso acceso (errore).
  final Color errorColor;

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
    this.onEditingComplete,
    this.errorText,
    this.errorColor = const Color(0xFFFF453A),
  });

  @override
  State<AmTextField> createState() => _AmTextFieldState();
}

class _AmTextFieldState extends State<AmTextField> {
  /// Stato locale del mascheramento. Parte dal valore richiesto dall'esterno
  /// e viene alternato dall'occhietto solo per i campi password.
  late bool _obscured = widget.obscureText;

  /// Suffisso da mostrare nel campo. Per i campi password è l'occhietto
  /// interattivo; altrimenti l'eventuale icona passata dall'esterno.
  Widget? get _suffix {
    if (!widget.obscureText) return widget.suffixIcon;
    return IconButton(
      onPressed: () => setState(() => _obscured = !_obscured),
      splashRadius: 20,
      icon: Icon(
        _obscured ? Icons.visibility_off : Icons.visibility,
        color: const Color(0xFF48484A),
      ),
    );
  }

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
                TextSpan(text: widget.label.toUpperCase()),
                if (widget.isRequired)
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
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: _obscured,
              keyboardType: widget.keyboardType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: hintColor,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                suffixIcon: _suffix,
              ),
              onChanged: widget.onChanged,
              onEditingComplete: widget.onEditingComplete,
            ),
          ),
          // Messaggio sotto il campo (errore rosso acceso o avviso rosso tenue).
          if (widget.errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorText!,
              style: TextStyle(
                color: widget.errorColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

        ],
      ),
    );
  }
}