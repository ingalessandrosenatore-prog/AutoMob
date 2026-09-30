import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes expose the matching AutoMob colors', () {
    expect(AmTheme.light.brightness, Brightness.light);
    expect(AmTheme.dark.brightness, Brightness.dark);
    expect(AmTheme.light.extension<AmThemeColors>(), same(AmThemeColors.light));
    expect(AmTheme.dark.extension<AmThemeColors>(), same(AmThemeColors.dark));
  });

  test('dark palette follows the HSL surface hierarchy', () {
    expect(AmThemeColors.dark.background, const Color(0xFF000000));
    expect(AmThemeColors.dark.surface, const Color(0xFF0D0D0D));
    expect(AmThemeColors.dark.surfaceRaised, const Color(0xFF1A1A1A));
    expect(AmThemeColors.dark.textPrimary, const Color(0xFFF2F2F2));
    expect(AmThemeColors.dark.textSecondary, const Color(0xFFB3B3B3));
    expect(AmThemeColors.dark.border, const Color(0xFF4D4D4D));
    expect(AmThemeColors.dark.borderHighlight, const Color(0xFF4D4D4D));
    expect(AmThemeColors.dark.cardGradientStart, const Color(0xFF262626));
    expect(AmThemeColors.dark.cardGradientEnd, const Color(0xFF1A1A1A));
    expect(AmThemeColors.dark.cardGradient.begin, Alignment.topCenter);
    expect(AmThemeColors.dark.cardGradient.end, Alignment.bottomCenter);
    expect(
      AmThemeColors.dark.cardBorderGradient.colors.first,
      const Color(0xFF4D4D4D),
    );
    expect(AmThemeColors.dark.cardBorderGradient.colors.last.a, 0);
    expect(AmThemeColors.dark.cardBorderGradient.stops, const [
      0,
      0.08,
      0.45,
      1,
    ]);
  });

  test('light palette follows the HSL surface hierarchy', () {
    expect(AmThemeColors.light.background, const Color(0xFFE6E6E6));
    expect(AmThemeColors.light.surface, const Color(0xFFFFFFFF));
    expect(AmThemeColors.light.surfaceRaised, const Color(0xFFFFFFFF));
    expect(AmThemeColors.light.textPrimary, const Color(0xFF0D0D0D));
    expect(AmThemeColors.light.textSecondary, const Color(0xFF4D4D4D));
    expect(AmThemeColors.light.border, const Color(0xFFF2F2F2));
    expect(AmThemeColors.light.borderHighlight, const Color(0xFFFFFFFF));
    expect(AmThemeColors.light.cardBorderGradient.colors.last.a, 0);
    expect(AmThemeColors.light.cardGradientStart, const Color(0xFFFFFFFF));
    expect(AmThemeColors.light.cardGradientEnd, const Color(0xFFF5F5F5));
    expect(AmThemeColors.light.shadowSoft, const Color(0x0D000000));
    expect(AmThemeColors.light.shadow, const Color(0x1A000000));
  });

  test('semantic accents expose primary and secondary variants', () {
    expect(AmThemeColors.dark.info, AmThemeColors.dark.infoPrimary);
    expect(AmThemeColors.light.info, AmThemeColors.light.infoPrimary);
    expect(
      AmThemeColors.dark.accentSecondary,
      isNot(AmThemeColors.dark.accent),
    );
    expect(AmThemeColors.light.infoSecondary, isNot(AmThemeColors.light.info));
  });
}
