import 'package:auto_mob_v1/core/theme/am_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cardBackground usa il blu previsto nei due temi', () {
    expect(AmThemeColors.dark.cardBackground, const Color(0xFF4A8CFF));
    expect(AmThemeColors.light.cardBackground, const Color(0xFF2E6AE6));
    expect(
      AmThemeColors.light.copyWith(cardBackground: Colors.red).cardBackground,
      Colors.red,
    );
  });
}
