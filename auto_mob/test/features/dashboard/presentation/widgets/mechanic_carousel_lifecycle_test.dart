import 'dart:async';

import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_3d_configuration.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_carousel.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_carousel_scene.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A stale scene must be released before any GPU getter is read. Fake throws
// on those getters, so this also detects accidentally displaying an old load.
class _LoadedScene extends Fake implements MechanicCarouselScene {
  int releases = 0;
  @override
  Future<void> release() async {
    releases++;
  }
}

void main() {
  testWidgets('rilascia carichi superati e completati dopo la chiusura', (
    tester,
  ) async {
    final first = Completer<MechanicCarouselScene>();
    final second = Completer<MechanicCarouselScene>();
    final oldScene = _LoadedScene();
    final newScene = _LoadedScene();
    Future<void> show(String id, bool scrolling) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AmThemeColors.light]),
        home: MechanicCarousel(
          isScrolling: scrolling,
          configurations: [Mechanic3dConfiguration(id: id, name: id)],
          loader: (_, configs) =>
              configs.single.id == 'a' ? first.future : second.future,
        ),
      ),
    );
    await show('a', false);
    await show('b', true);
    first.complete(oldScene);
    await tester.pump();
    expect(oldScene.releases, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await show('b', false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    second.complete(newScene);
    await tester.pump();
    expect(newScene.releases, 1);
    expect(tester.takeException(), isNull);
  });
}
