import 'dart:async';

import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mecchainic_3d.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows loading and does not reload on parent rebuild', (
    tester,
  ) async {
    final pending = Completer<MechanicScene>();
    var calls = 0;
    Future<MechanicScene> load(String path) {
      calls++;
      expect(path, 'lib/assets/mascot/automob_mascot.glb');
      return pending.future;
    }

    final widget = MaterialApp(
      home: SizedBox(
        height: 320,
        child: Mecchainic3d(
          assetPath: 'lib/assets/mascot/automob_mascot.glb',
          loader: load,
        ),
      ),
    );
    await tester.pumpWidget(widget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(widget);
    expect(calls, 1);
    pending.completeError(StateError('Asset non disponibile'));
    await tester.pump();
    expect(find.textContaining('Asset non disponibile'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
