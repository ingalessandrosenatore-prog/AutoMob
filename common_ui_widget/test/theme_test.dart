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
}
