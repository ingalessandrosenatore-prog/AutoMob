import 'dart:async';

import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_model_cache.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'condivide un caricamento e rilascia una volta anche se ancora in corso',
    () async {
      final pending = Completer<Node>();
      var loads = 0;
      var releases = 0;
      final cache = MechanicModelCache(
        'mascot.glb',
        loader: (_) {
          loads++;
          return pending.future;
        },
        releaser: (_) async {
          releases++;
        },
      );
      final first = cache.load();
      final second = cache.load();
      expect(loads, 1);
      final disposal = cache.dispose();
      pending.complete(Node());
      expect(identical(await first, await second), isTrue);
      await disposal;
      await cache.dispose();
      expect(releases, 1);
      expect(cache.load, throwsStateError);
    },
  );

  test(
    'un errore non resta in cache e non rilascia risorse mai acquisite',
    () async {
      var loads = 0;
      var releases = 0;
      final cache = MechanicModelCache(
        'mascot.glb',
        loader: (_) async {
          if (++loads == 1) throw StateError('failed');
          return Node();
        },
        releaser: (_) async {
          releases++;
        },
      );
      await expectLater(cache.load(), throwsStateError);
      await cache.load();
      expect(loads, 2);
      await cache.dispose();
      expect(releases, 1);
    },
  );
}
