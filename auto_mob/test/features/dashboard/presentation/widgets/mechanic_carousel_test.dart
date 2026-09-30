import 'dart:async';

import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_3d_configuration.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_actor.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_carousel.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_carousel_layout.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/mechanic_carousel_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart' as scene;
// Solo nel test: il barrel pubblico non esporta i costruttori dei keyframe.
// ignore: implementation_imports
import 'package:flutter_scene/src/animation.dart' as scene;
import 'package:flutter_test/flutter_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  testWidgets(
    'durante lo swipe mostra lo spinner e carica solo l ultima auto',
    (tester) async {
      final pending = Completer<MechanicCarouselScene>();
      final loadedIds = <String>[];
      Future<void> show(String id, bool scrolling) => tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AmThemeColors.light]),
          home: MechanicCarousel(
            isScrolling: scrolling,
            configurations: [Mechanic3dConfiguration(id: id, name: id)],
            loader: (_, configs) {
              loadedIds.add(configs.single.id);
              return pending.future;
            },
          ),
        ),
      );
      await show('a', true);
      await show('b', true);
      expect(loadedIds, isEmpty);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await show('b', false);
      expect(loadedIds, ['b']);
      await show('b', true);
      await show('b', false);
      expect(loadedIds, ['b']);
      pending.completeError(StateError('fine test'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  test('configurazione descrive le clip e confronta i valori', () {
    const config = Mechanic3dConfiguration(id: 'a', name: 'A');
    expect(config, const Mechanic3dConfiguration(id: 'a', name: 'A'));
    expect(config.idleClip, 'standing_wrench_idle');
    expect(config.actionClip, 'standing_wrench_spin');
  });

  test('slot principale davanti e interpolazione continua', () {
    expect(MechanicCarouselLayout.at(0).scale, 1);
    expect(MechanicCarouselLayout.at(0).x, -.02);
    expect(MechanicCarouselLayout.at(-1).x, -.35);
    expect(MechanicCarouselLayout.at(1).x, .30);
    expect(MechanicCarouselLayout.at(-1).x, lessThan(0));
    expect(MechanicCarouselLayout.at(1).depth, greaterThan(0));
    expect(
      MechanicCarouselLayout.at(2).scale,
      lessThan(MechanicCarouselLayout.at(1).scale),
    );
    expect(MechanicCarouselLayout.at(.5).scale, closeTo(.87, .0001));
    expect(MechanicCarouselLayout.at(-4).opacity, 0);
    expect(MechanicCarouselLayout.at(5).opacity, 0);
  });

  test('ogni omino ha un nodo e una clip indipendenti', () {
    final template = scene.Node();
    for (final pose in ['standing', 'desk']) {
      final root = scene.Node(name: 'AM_${pose.toUpperCase()}');
      template.add(root);
      for (final tool in ['wrench', 'screwdriver', 'tablet', 'tire']) {
        root.add(scene.Node(name: '${pose}_PROP_$tool'));
      }
      if (pose == 'desk') root.add(scene.Node(name: 'desk_WORKBENCH'));
    }
    template.addParsedAnimation(scene.Animation(name: 'standing_wrench_spin'));
    template.addParsedAnimation(scene.Animation(name: 'standing_wrench_idle'));
    final a = MechanicActor(
      template,
      const Mechanic3dConfiguration(id: 'a', name: 'A'),
    );
    final b = MechanicActor(
      template,
      const Mechanic3dConfiguration(id: 'b', name: 'B'),
    );
    expect(identical(a.model, b.model), isFalse);
    a.activate();
    expect(a.isAnimating, isTrue);
    expect(b.isAnimating, isFalse);
    a.freeze();
    b.activate();
    expect(a.isAnimating, isFalse);
    expect(b.isAnimating, isTrue);
    expect(a.model.getChildByName('AM_DESK')!.visible, isFalse);
    expect(a.model.getChildByName('standing_PROP_tablet')!.visible, isFalse);
    expect(
      a.model.getChildByName('desk_WORKBENCH')!.scale.x,
      closeTo(.60, .001),
    );
  });

  testWidgets('segue il dito, seleziona solo al rilascio e raggiunge il +', (
    tester,
  ) async {
    final pending = Completer<MechanicCarouselScene>();
    final selected = <int>[];
    var addTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AmThemeColors.light]),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: MechanicCarousel(
                configurations: const [
                  Mechanic3dConfiguration(id: 'a', name: 'A'),
                ],
                loader: (_, _) => pending.future,
                onSelected: selected.add,
                onAdd: () => addTaps++,
              ),
            ),
          ),
        ),
      ),
    );
    final first = find.byKey(const ValueKey('mechanic_slot_0'));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Collega officina'), findsNothing);
    expect(tester.getSize(find.byType(MechanicCarousel)).height, 224);
    final edges = tester.widget<SmartEdge>(find.byType(SmartEdge));
    expect(edges.blur, isFalse);
    expect(edges.edges.map((edge) => edge.type), [
      EdgeType.leftEdge,
      EdgeType.rightEdge,
    ]);
    expect(edges.edges.every((edge) => edge.size == 100), isTrue);
    expect(
      tester.getTopLeft(first).dx,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('mechanic_slot_1'))).dx,
      ),
    );
    expect(
      tester.getBottomLeft(first).dy,
      lessThan(
        tester.getBottomLeft(find.byKey(const ValueKey('mechanic_slot_1'))).dy,
      ),
    );
    final before = tester.getTopLeft(first).dx;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('mechanic_carousel_swipe'))),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(85, 0));
    await tester.pump();
    expect(tester.getTopLeft(first).dx, greaterThan(before));
    expect(selected, isEmpty);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 250));
    expect(selected, [0]);
    expect(find.text('A'), findsNothing);
    expect(find.text('Collega officina'), findsOneWidget);
    await tester.tap(find.text('Collega officina'));
    expect(addTaps, 1);
    pending.completeError(StateError('test load error'));
    await tester.pump();
    expect(find.textContaining('Caricamento 3D non riuscito'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('liste equivalenti non ricaricano la scena', (tester) async {
    final pending = Completer<MechanicCarouselScene>();
    var loads = 0;
    for (final selection in [1, 1, 0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AmThemeColors.light]),
          home: MechanicCarousel(
            configurations: List.of(const [
              Mechanic3dConfiguration(id: 'a', name: 'A'),
            ]),
            selectedIndex: selection,
            loader: (_, _) {
              loads++;
              return pending.future;
            },
          ),
        ),
      );
    }
    expect(loads, 1);
    pending.completeError(StateError('fine test'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('senza officine il + funziona senza caricare il GLB', (
    tester,
  ) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AmThemeColors.light]),
        home: MechanicCarousel(
          configurations: const [],
          loader: (_, _) => throw StateError('Non deve caricare'),
          onAdd: () => added = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final plusIcon = find.byIcon(Icons.add_circle_outline);
    final restingWidth = tester.getRect(plusIcon).width;
    await tester.pump(const Duration(milliseconds: 650));
    expect(tester.getRect(plusIcon).width, greaterThan(restingWidth));
    await tester.tap(find.text('Collega officina'));
    expect(added, isTrue);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'ossa omonime: posa iniziale e movimento solo sullo scheletro scelto',
    () {
      final template = scene.Node();
      for (final pose in ['desk', 'standing']) {
        template.add(
          scene.Node(name: 'AM_${pose.toUpperCase()}')
            ..add(scene.Node(name: 'wrist.L')),
        );
        for (final gesture in ['idle', 'spin']) {
          template.addParsedAnimation(
            scene.Animation(
              name: '${pose}_wrench_$gesture',
              channels: [
                scene.AnimationChannel(
                  bindTarget: scene.BindKey(nodeName: 'wrist.L'),
                  resolver: scene.PropertyResolver.makeTranslationTimeline(
                    [0, 1],
                    [vm.Vector3(0, 2, 0), vm.Vector3(0, 4, 0)],
                  ),
                ),
              ],
            ),
          );
        }
      }
      for (final pose in ['standing', 'desk']) {
        final actor = MechanicActor(
          template,
          Mechanic3dConfiguration(id: pose, name: pose, pose: pose),
        );
        final hand = actor.model
            .getChildByName('AM_${pose.toUpperCase()}')!
            .getChildByName('wrist.L')!;
        final other = actor.model
            .getChildByName(pose == 'standing' ? 'AM_DESK' : 'AM_STANDING')!
            .getChildByName('wrist.L')!;
        expect(hand.position.y, 2);
        expect(other.position.y, 0);
        actor.activate();
        actor.tick(.5);
        expect(hand.position.y, closeTo(3, .001));
        expect(other.position.y, 0);
        actor.freeze();
        actor.tick(.5);
        expect(hand.position.y, 2);
        expect(actor.isAnimating, isFalse);
      }
    },
  );
}
