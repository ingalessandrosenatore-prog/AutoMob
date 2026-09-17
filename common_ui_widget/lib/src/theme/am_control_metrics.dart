import 'package:flutter/material.dart';

/// Misure condivise per i controlli compatti e i menu AutoMob.
abstract final class AmControlMetrics {
  static const pullDownWidth = 250.0;
  static const pullDownRadius = 29.0;
  static const pullDownPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 10,
  );
  static const pullDownRowHeight = 52.0;
  static const pullDownItemGap = 14.0;
  static const pullDownIconSize = 20.0;
  static const pullDownTriggerHeight = 40.0;
  static const minimumTouchTarget = 44.0;

  static const circularButtonVisualSize = 40.0;
  static const circularButtonIconSize = 20.0;

  static const mediumButtonHeight = 38.0;
  static const mediumButtonHorizontalPadding = 17.0;
  static const standardButtonHeight = 44.0;
  static const standardButtonHorizontalPadding = 19.0;

  static Color pullDownFill(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color.fromRGBO(255, 255, 255, 0.78),
    Brightness.dark => const Color.fromRGBO(28, 28, 30, 0.78),
  };

  static Color pullDownPopupFill(Brightness brightness) => switch (brightness) {
    Brightness.light => const Color.fromRGBO(255, 255, 255, 0.80),
    Brightness.dark => const Color.fromRGBO(28, 28, 30, 0.80),
  };

  static BoxShadow pullDownShadow(Brightness brightness) =>
      switch (brightness) {
        Brightness.light => const BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.06),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
        Brightness.dark => const BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.30),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      };
}
