import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Disattiva temporaneamente le superfici Liquid Glass durante lo spostamento
/// del PageView che contiene i controlli.
class AmLiquidGlassMotionScope
    extends InheritedNotifier<ValueListenable<bool>> {
  const AmLiquidGlassMotionScope({
    required ValueListenable<bool> isMoving,
    required super.child,
    super.key,
  }) : super(notifier: isMoving);

  static bool isMovingOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AmLiquidGlassMotionScope>()
          ?.notifier
          ?.value ??
      false;
}
