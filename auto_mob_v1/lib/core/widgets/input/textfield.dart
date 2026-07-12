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

  /// Altezza fissa del box (testo centrato verticalmente). Null (default) =
  /// dimensione naturale di sempre (padding verticale 20), per non toccare
  /// l'aspetto dei campi gia' esistenti in app.
  final double? height;

  /// Colore applicato a [suffixIcon] (es. l'icona o l'unita' di misura "km"
  /// passata dall'esterno), se questa non fissa gia' un colore proprio.
  /// Null (default) = nessuna sovrascrittura.
  final Color? suffixIconColor;

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
    this.height,
    this.suffixIconColor,
  });

  @override
  State<AmTextField> createState() => _AmTextFieldState();
}

class _AmTextFieldState extends State<AmTextField> {
  /// Stato locale del mascheramento. Parte dal valore richiesto dall'esterno
  /// e viene alternato dall'occhietto solo per i campi password.
  late bool _obscured = widget.obscureText;

  /// Suffisso da mostrare nel campo. Per i campi password è l'occhietto
  /// interattivo; altrimenti l'eventuale icona passata dall'esterno, colorata
  /// con [AmTextField.suffixIconColor] se impostato.
  Widget? get _suffix {
    if (!widget.obscureText) {
      final icon = widget.suffixIcon;
      if (icon == null || widget.suffixIconColor == null) return icon;
      return IconTheme.merge(
        data: IconThemeData(color: widget.suffixIconColor),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: widget.suffixIconColor),
          child: icon,
        ),
      );
    }
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
            height: widget.height,
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
              expands: widget.height != null,
              maxLines: widget.height != null ? null : 1,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: widget.height != null
                    ? const EdgeInsets.symmetric(horizontal: 16)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                hintText: widget.placeholder,
                hintStyle: const TextStyle(color: hintColor, fontSize: 16),
                border: InputBorder.none,
                suffixIcon: _suffix,
                // Di default Flutter riserva 48x48 al suffixIcon (tap target
                // minimo): con un box di altezza fissa (compatto) questo
                // spinge l'icona fuori centro rispetto al testo. Rimuoviamo
                // il minimo cosi' l'icona resta centrata nel box.
                suffixIconConstraints: widget.height != null
                    ? const BoxConstraints()
                    : null,
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
