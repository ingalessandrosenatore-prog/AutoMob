import 'package:flutter/material.dart';

class AmThemeColors extends ThemeExtension<AmThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceHighlight;
  final Color surfaceDeep;
  final Color textPrimary;
  final Color textSecondary;
  final Color onMedia;
  final Color border;
  final Color accent;
  final Color info;
  final Color danger;
  final Color shadow;

  const AmThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceHighlight,
    required this.surfaceDeep,
    required this.textPrimary,
    required this.textSecondary,
    required this.onMedia,
    required this.border,
    required this.accent,
    required this.info,
    required this.danger,
    required this.shadow,
  });

  static const dark = AmThemeColors(
    background: Color(0xFF0F0F11), // Colore di sfondo principale
    surface: Color(0xFF1C1C1E), // Superficie standard (es. card, fogli)
    surfaceRaised: Color(
      0xFF2C2C2E,
    ), // Superficie leggermente sollevata o in rilievo
    surfaceHighlight: Color(
      0xFF343438,
    ), // Superficie evidenziata o più luminosa
    surfaceDeep: Color(0xFF171719), // Superficie più profonda o incassata
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E8E93),
    onMedia: Color(0xFFFFFFFF),
    border: Colors.transparent,
    accent: Color(0xFFFF6B00),
    info: Color(0xFF3192F3),
    danger: Color(0xFFFF453A),
    shadow: Color(0x99000000),
  );

  static const light = AmThemeColors(
    background: Color(
      0xFFFAF8F6,
    ), // Grigio di sistema iOS-like, pulito e moderno
    surface: Color(0xFFFFFFFF), // Bianco puro per risaltare sullo sfondo
    surfaceRaised: Color(0xFFFFFFFF), // Leggera elevazione quasi impercettibile
    surfaceHighlight: Color(0xFFFFFFFF), // Stato hover o selezione chiaro
    surfaceDeep: Color(0xFFE9E9EB), // Per input fields o aree incassate
    textPrimary: Color(
      0xFF000000,
    ), // Quasi nero, riduce l'affaticamento visivo (WCAG AAA)
    textSecondary: Color(
      0xFF636366,
    ), // Grigio medio per gerarchia (WCAG AA su bianco)
    onMedia: Color(0xFFFFFFFF), // Testo su immagini o colori pieni
    border: Colors.transparent, // Bordo sottile visibile ma non invasivo
    accent: Color(0xFFFF6B00), // Il tuo arancione distintivo
    info: Color(0xFF007AFF), // Blu standard per accessibilità e chiarezza
    danger: Color(0xFFFF3B30), // Rosso errore standard UI moderna
    shadow: Color(0x44000000), // Ombra molto morbida (10% opacità)
  );

  static AmThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AmThemeColors>()!;

  @override
  Object get type => AmThemeColors;

  @override
  AmThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceHighlight,
    Color? surfaceDeep,
    Color? textPrimary,
    Color? textSecondary,
    Color? onMedia,
    Color? border,
    Color? accent,
    Color? info,
    Color? danger,
    Color? shadow,
  }) => AmThemeColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceHighlight: surfaceHighlight ?? this.surfaceHighlight,
    surfaceDeep: surfaceDeep ?? this.surfaceDeep,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    onMedia: onMedia ?? this.onMedia,
    border: border ?? this.border,
    accent: accent ?? this.accent,
    info: info ?? this.info,
    danger: danger ?? this.danger,
    shadow: shadow ?? this.shadow,
  );

  @override
  AmThemeColors lerp(ThemeExtension<AmThemeColors>? other, double t) {
    if (other is! AmThemeColors) return this;
    return AmThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceHighlight: Color.lerp(
        surfaceHighlight,
        other.surfaceHighlight,
        t,
      )!,
      surfaceDeep: Color.lerp(surfaceDeep, other.surfaceDeep, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      onMedia: Color.lerp(onMedia, other.onMedia, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
