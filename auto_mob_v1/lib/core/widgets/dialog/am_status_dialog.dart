import 'dart:ui';

import 'package:flutter/material.dart';

/// Una singola azione (bottone) di un [AmStatusDialog].
/// [filled] true = bottone pieno (azione primaria, es. "Riprova"),
/// false = solo testo (azione secondaria, es. "Chiudi").
class AmDialogAction {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;

  const AmDialogAction({
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });
}

/// Pop-up di stato riutilizzabile in stile iOS: vetro sfocato, bordi
/// arrotondati, icona colorata, titolo, messaggio e fino a N azioni.
///
/// Tre usi tipici:
/// - caricamento  -> [showSpinner] true, niente azioni;
/// - errore       -> icona rossa + azioni "Riprova"/"Chiudi";
/// - warning      -> icona soft + azioni "Aggiungi"/"Chiudi".
///
/// Non si mostra da solo: usare [showAmStatusDialog].
class AmStatusDialog extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String? message;
  final List<AmDialogAction> actions;
  final bool showSpinner;

  const AmStatusDialog({
    super.key,
    this.icon,
    this.iconColor = const Color(0xFFFF6B00),
    required this.title,
    this.message,
    this.actions = const [],
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(iconColor),
                    ),
                  )
                else if (icon != null)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 34),
                  ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9A9AA0),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: _ActionButton(action: actions[i])),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AmDialogAction action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.filled ? action.color : action.color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onPressed,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            action.label,
            style: TextStyle(
              color: action.filled ? Colors.white : action.color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mostra un [AmStatusDialog]. Di default NON si chiude toccando fuori
/// (loading ed errori devono restare finche' non si sceglie un'azione).
Future<T?> showAmStatusDialog<T>(
  BuildContext context, {
  IconData? icon,
  Color iconColor = const Color(0xFFFF6B00),
  required String title,
  String? message,
  List<AmDialogAction> actions = const [],
  bool showSpinner = false,
  bool barrierDismissible = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => AmStatusDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      actions: actions,
      showSpinner: showSpinner,
    ),
  );
}
