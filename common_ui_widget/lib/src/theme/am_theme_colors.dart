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
  final Color borderHighlight;
  final Color accent;
  final Color accentSecondary;
  final Color infoPrimary;
  final Color infoSecondary;
  final Color danger;
  final Color cardBackground;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color shadowSoft;
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
    required this.borderHighlight,
    required this.accent,
    required this.accentSecondary,
    required this.infoPrimary,
    required this.infoSecondary,
    required this.danger,
    required this.cardBackground,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.shadowSoft,
    required this.shadow,
  });

  /// Alias mantenuto per i componenti esistenti durante la migrazione.
  Color get info => infoPrimary;

  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardGradientStart, cardGradientEnd],
  );

  LinearGradient get cardBorderGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      borderHighlight,
      borderHighlight,
      borderHighlight.withValues(alpha: 0.35),
      borderHighlight.withValues(alpha: 0),
    ],
    stops: const [0, 0.08, 0.45, 1],
  );

  List<BoxShadow> get cardShadows => [
    BoxShadow(color: shadowSoft, blurRadius: 2, offset: const Offset(0, 2)),
    BoxShadow(color: shadow, blurRadius: 4, offset: const Offset(0, 4)),
  ];

  static const dark = AmThemeColors(
    background: Color(0xFF000000), // hsl(0, 0%, 0%)
    surface: Color(0xFF0D0D0D), // hsl(0, 0%, 5%)
    surfaceRaised: Color(0xFF1A1A1A), // hsl(0, 0%, 10%)
    surfaceHighlight: Color(0xFF262626),
    surfaceDeep: Color(0xFF0D0D0D),
    textPrimary: Color(0xFFF2F2F2), // hsl(0, 0%, 95%)
    textSecondary: Color(0xFFB3B3B3), // hsl(0, 0%, 70%)
    onMedia: Color(0xFFFFFFFF),
    border: Color(0xFF4D4D4D), // hsl(0, 0%, 30%)
    borderHighlight: Color(0xFF4D4D4D), // hsl(0, 0%, 30%)
    accent: Color(0xFFFF6B00),
    accentSecondary: Color(0xFF663000),
    infoPrimary: Color(0xFF3192F3),
    infoSecondary: Color(0xFF123A63),
    danger: Color(0xFFFF453A),
    cardBackground: Color(0xFF4A8CFF),
    cardGradientStart: Color(0xFF262626), // hsl(0, 0%, 15%)
    cardGradientEnd: Color(0xFF1A1A1A), // hsl(0, 0%, 10%)
    shadowSoft: Color(0x12000000), // hsla(0, 0%, 0%, 0.07)
    shadow: Color(0x99000000),
  );

  static const light = AmThemeColors(
    background: Color(0xFFE6E6E6), // hsl(0, 0%, 90%)
    surface: Color(0xFFFFFFFF), // hsl(0, 0%, 100%)
    surfaceRaised: Color(0xFFFFFFFF), // hsl(0, 0%, 100%)
    surfaceHighlight: Color(0xFFFFFFFF),
    surfaceDeep: Color(0xFFE6E6E6),
    textPrimary: Color(0xFF0D0D0D), // hsl(0, 0%, 5%)
    textSecondary: Color(0xFF4D4D4D), // hsl(0, 0%, 30%)
    onMedia: Color(0xFFFFFFFF),
    border: Color(0xFFF2F2F2), // come bg/card
    borderHighlight: Color(0xFFFFFFFF), // luce dall'alto
    accent: Color(0xFFFF6B00),
    accentSecondary: Color(0xFFFFB37A),
    infoPrimary: Color(0xFF007AFF),
    infoSecondary: Color(0xFF8FC7FF),
    danger: Color(0xFFFF3B30),
    cardBackground: Color(0xFF2E6AE6),
    cardGradientStart: Color(0xFFFFFFFF), // hsl(0, 0%, 100%)
    cardGradientEnd: Color(0xFFF5F5F5), // hsl(0, 0%, 96%)
    shadowSoft: Color(0x0D000000), // hsla(0, 0%, 0%, 0.05)
    shadow: Color(0x1A000000), // hsla(0, 0%, 0%, 0.10)
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
    Color? borderHighlight,
    Color? accent,
    Color? accentSecondary,
    Color? infoPrimary,
    Color? infoSecondary,
    Color? danger,
    Color? cardBackground,
    Color? cardGradientStart,
    Color? cardGradientEnd,
    Color? shadowSoft,
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
    borderHighlight: borderHighlight ?? this.borderHighlight,
    accent: accent ?? this.accent,
    accentSecondary: accentSecondary ?? this.accentSecondary,
    infoPrimary: infoPrimary ?? this.infoPrimary,
    infoSecondary: infoSecondary ?? this.infoSecondary,
    danger: danger ?? this.danger,
    cardBackground: cardBackground ?? this.cardBackground,
    cardGradientStart: cardGradientStart ?? this.cardGradientStart,
    cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
    shadowSoft: shadowSoft ?? this.shadowSoft,
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
      borderHighlight: Color.lerp(borderHighlight, other.borderHighlight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      infoPrimary: Color.lerp(infoPrimary, other.infoPrimary, t)!,
      infoSecondary: Color.lerp(infoSecondary, other.infoSecondary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardGradientStart: Color.lerp(
        cardGradientStart,
        other.cardGradientStart,
        t,
      )!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
