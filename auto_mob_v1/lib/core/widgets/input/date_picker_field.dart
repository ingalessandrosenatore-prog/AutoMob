import 'package:flutter/material.dart';

/// Campo selettore data AutoMob.
/// Stesso stile di [AmTextField]: invece di far digitare l'utente, apre un
/// calendario nativo a tema scuro e scrive la data scelta nel [controller]
/// nel formato `gg/mm/aaaa`, così il resto del codice (parsing, variabili)
/// resta invariato.
class AmDatePickerField extends StatefulWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool isRequired;

  /// Chiamata quando l'utente sceglie una data dal calendario.
  final ValueChanged<DateTime>? onDateSelected;

  /// Limiti del calendario. Se non passati usa un range ragionevole.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Altezza fissa del box (contenuto centrato verticalmente). Null
  /// (default) = dimensione naturale di sempre (padding verticale 20).
  final double? height;

  const AmDatePickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.isRequired = false,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.height,
  });

  @override
  State<AmDatePickerField> createState() => _AmDatePickerFieldState();
}

class _AmDatePickerFieldState extends State<AmDatePickerField> {
  static const Color labelColor = Color(0xFF636366);
  static const Color asteriskColor = Color(0xFF4A90E2);
  static const Color boxColor = Color(0xFF1C1C1E);
  static const Color hintColor = Color(0xFF48484A);
  static const Color accent = Color(0xFFE85A1A);

  DateTime? _parse(String text) {
    if (text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String _format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(now.year - 30);
    final last = widget.lastDate ?? DateTime(now.year + 30);
    final current = _parse(widget.controller.text);
    final initial =
        (current != null && !current.isBefore(first) && !current.isAfter(last))
        ? current
        : (now.isBefore(first) ? first : (now.isAfter(last) ? last : now));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: accent,
              onPrimary: Colors.white,
              surface: Color(0xFF151517),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: accent),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF151517),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        widget.controller.text = _format(picked);
      });
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;

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
          // Box "finto textfield" cliccabile
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: widget.height != null ? 0 : 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasValue ? widget.controller.text : widget.placeholder,
                        style: TextStyle(
                          color: hasValue ? Colors.white : hintColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      color: hintColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
