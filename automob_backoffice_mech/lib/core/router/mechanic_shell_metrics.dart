import 'package:flutter/widgets.dart';

abstract final class MechanicShellMetrics {
  static const horizontalMargin = 16.0;
  static const navigationHeight = 62.0;
  static const microphoneSize = 62.0;
  static const controlSpacing = 140.0;
  static const searchHeight = 52.0;
  static const searchNavigationGap = 6.0;
  static const bottomMargin = 10.0;
}

class MechanicShellGeometry extends InheritedWidget {
  const MechanicShellGeometry({
    required this.controlsBottom,
    required super.child,
    super.key,
  });

  final double controlsBottom;

  static MechanicShellGeometry of(BuildContext context) {
    final geometry = context
        .dependOnInheritedWidgetOfExactType<MechanicShellGeometry>();
    assert(
      geometry != null,
      'MechanicShellGeometry non trovata sopra la Home.',
    );
    return geometry!;
  }

  @override
  bool updateShouldNotify(MechanicShellGeometry oldWidget) =>
      controlsBottom != oldWidget.controlsBottom;
}
