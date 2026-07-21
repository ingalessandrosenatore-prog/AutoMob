import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

import 'am_theme_colors.dart';

const _alertDialogSmoothing = 0.8;

const _alertDialogShape = SmoothRectangleBorder(
  borderRadius: SmoothBorderRadius.all(
    SmoothRadius(cornerRadius: 36, cornerSmoothing: _alertDialogSmoothing),
  ),
);

class AmTheme {
  const AmTheme._();

  static ThemeData get dark =>
      _build(colors: AmThemeColors.dark, brightness: Brightness.dark);

  static ThemeData get light =>
      _build(colors: AmThemeColors.light, brightness: Brightness.light);

  static ThemeData _build({
    required AmThemeColors colors,
    required Brightness brightness,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          error: colors.danger,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.onMedia,
          outline: colors.border,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surfaceRaised,
          surfaceContainerHighest: colors.surfaceHighlight,
        );
    final base = ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.border,
      iconTheme: IconThemeData(color: colors.textPrimary),
      textTheme: base.textTheme.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.shadow,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceRaised,
        indicatorColor: colors.accent.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.accent
                : colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: _alertDialogShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.textSecondary),
        labelStyle: TextStyle(color: colors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.accent),
        ),
      ),
      extensions: [colors],
    );
  }
}
