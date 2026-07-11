import 'package:flutter/services.dart';

/// Feedback aptico centralizzato per AutoMob.
///
/// Unico punto dell'app che parla con [HapticFeedback]: i widget interattivi
/// chiamano questi metodi invece del canale di sistema, così l'intensità per
/// tipo di interazione resta coerente in tutta l'app e può essere spenta
/// globalmente (futuro toggle nelle impostazioni) tramite [enabled].
class AmHaptics {
  AmHaptics._();

  /// Interruttore globale (futuro toggle utente nelle impostazioni).
  static bool enabled = true;

  /// Tocco leggero: bottoni e voci di menu.
  static void tap() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Azione importante: submit, salvataggi, trigger del pull-to-refresh.
  static void action() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Esito rilevante: conferma di un'operazione andata a buon fine.
  static void success() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Cambio di selezione: chip, dropdown, step del wizard, bottom bar.
  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }
}
