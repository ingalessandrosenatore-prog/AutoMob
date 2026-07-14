import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';

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

    final colors = AmThemeColors.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: colors.accent,
              surface: colors.surface,
              onSurface: colors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: colors.accent),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colors.surface,
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
    final colors = AmThemeColors.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label superiore con asterisco condizionale
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
              children: [
                TextSpan(text: widget.label.toUpperCase()),
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: colors.info),
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.border,
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
                          color: hasValue
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      color: colors.textSecondary,
                      size: 18,
                      strokeWidth: 2.2,
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
