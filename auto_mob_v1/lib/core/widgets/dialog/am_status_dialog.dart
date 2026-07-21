import 'dart:ui';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

import '../../config/performance_flags.dart';
import '../../theme/am_theme_colors.dart';

const _dialogCornerSmoothing = 0.8;

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
      child: _DialogSurface(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: icon!,
                    color: iconColor,
                    size: 34,
                    strokeWidth: 2.2,
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
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

/// Quando il liquid glass è disattivo non monta il [BackdropFilter]: al suo
/// posto mantiene il bordo luminoso con la sfumatura della tinta del tema.
class _DialogSurface extends StatelessWidget {
  final Color color;
  final Widget child;

  const _DialogSurface({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    const radius = 36.0;
    final surface = color.withValues(alpha: 0.88);

    if (kHeavyEffects) {
      return OCLiquidGlassGroup(
        settings: const OCLiquidGlassSettings(
          refractStrength: -0.12,
          blurRadiusPx: 4.0,
          specStrength: 0,
          specWidth: 0.0,
          specAngle: 145,
          blendPx: 70,
          specPower: 10,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: _dialogShape(radius: radius)),
          child: OCLiquidGlass(
            color: color.withValues(alpha: 0.8),
            borderRadius: radius,
            child: child,
          ),
        ),
      );
    }

    return ClipPath(
      clipper: ShapeBorderClipper(shape: _dialogShape(radius: radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: ShapeDecoration(
            color: surface,
            shape: _dialogShape(radius: radius),
          ),
          child: child,
        ),
      ),
    );
  }
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
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.55),
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
