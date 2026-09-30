import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards page and local control repaint through one controller', () {
    final pageRepaint = ChangeNotifier();
    final controller = AmLiquidGlassRepaintController()
      ..bindExternalRepaint(pageRepaint);
    addTearDown(pageRepaint.dispose);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    pageRepaint.notifyListeners();
    controller.updateScale(1.1);

    expect(notifications, 2);
  });
}
