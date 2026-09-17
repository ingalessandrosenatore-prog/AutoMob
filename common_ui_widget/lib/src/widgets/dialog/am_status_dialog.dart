import 'dart:ui';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../theme/am_theme_colors.dart';
import '../effects/am_static_frosted_surface.dart';

const _dialogCornerSmoothing = 0.8;
const _dialogWidth = 248.0;
const _dialogRadius = 30.0;

SmoothRectangleBorder _dialogShape({double radius = 36}) =>
    SmoothRectangleBorder(
      borderRadius: SmoothBorderRadius(
        cornerRadius: radius,
        cornerSmoothing: _dialogCornerSmoothing,
      ),
    );

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

/// Pop-up di stato riutilizzabile in stile iOS: superficie statica sfocata, bordi
/// arrotondati, icona colorata, titolo, messaggio e fino a N azioni.
///
/// Tre usi tipici:
/// - caricamento  -> [showSpinner] true, niente azioni;
/// - errore       -> icona rossa + azioni "Riprova"/"Chiudi";
/// - warning      -> icona soft + azioni "Aggiungi"/"Chiudi".
///
/// Non si mostra da solo: usare [showAmStatusDialog].
class AmStatusDialog extends StatelessWidget {
  final List<List>? icon;
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
    final colors = AmThemeColors.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      constraints: const BoxConstraints.tightFor(width: _dialogWidth),
      child: SizedBox(
        width: _dialogWidth,
        child: _DialogSurface(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: icon!,
                      color: iconColor,
                      size: 30,
                      strokeWidth: 2.2,
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
      color: action.filled
          ? action.color
          : action.color.withValues(alpha: 0.12),
      shape: _dialogShape(radius: 25),
      child: InkWell(
        customBorder: _dialogShape(radius: 25),
        onTap: action.onPressed,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            action.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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

/// Superficie statica del dialog: mantiene solo il blur dello sfondo, senza
/// rifrazione o animazioni Liquid Glass.
class _DialogSurface extends StatelessWidget {
  final Widget child;

  const _DialogSurface({required this.child});

  @override
  Widget build(BuildContext context) => AmStaticFrostedSurface(
    surfaceKey: const Key('am-status-dialog-static-surface'),
    blurKey: const Key('am-status-dialog-backdrop-blur'),
    decorationKey: const Key('am-status-dialog-gradient-surface'),
    borderRadius: _dialogRadius,
    child: child,
  );
}

/// Mostra un [AmStatusDialog]. Di default NON si chiude toccando fuori
/// (loading ed errori devono restare finche' non si sceglie un'azione).
Future<T?> showAmStatusDialog<T>(
  BuildContext context, {
  List<List>? icon,
  Color iconColor = const Color(0xFFFF6B00),
  required String title,
  String? message,
  List<AmDialogAction> actions = const [],
  bool showSpinner = false,
  bool barrierDismissible = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
    pageBuilder: (_, animation, secondaryAnimation) => Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          key: const Key('am-status-dialog-page-blur'),
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: const SizedBox.expand(),
        ),
        Center(
          child: AmStatusDialog(
            icon: icon,
            iconColor: iconColor,
            title: title,
            message: message,
            actions: actions,
            showSpinner: showSpinner,
          ),
        ),
      ],
    ),
  );
}
